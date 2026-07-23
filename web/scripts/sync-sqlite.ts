import { loadScriptEnv } from "../load-script-env";

loadScriptEnv();
import Database from "better-sqlite3";
import { and, desc, eq, inArray, isNotNull, notExists, sql } from "drizzle-orm";
import { drizzle } from "drizzle-orm/postgres-js";
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import path from "node:path";
import postgres from "postgres";
import * as schema from "../db/schema";
import {
  type SqliteDeal,
  type SqliteDealSchedule,
  syncVenueDeals,
} from "./sync-deals";

type RegionCatalogEntry = {
  name: string;
  status: string;
};

type SqliteSuburb = {
  id: number;
  name: string;
  postcode: string | null;
  state: string | null;
  lat: number | null;
  lng: number | null;
  sqkm: number | null;
  population: number | null;
  statistic_area: string | null;
  region_id: number | null;
  hero_image: string | null;
  hero_r2_url: string | null;
};

type SqliteCountry = {
  id: number;
  name: string;
  iso3: string;
};

type SqliteGeographicRegion = {
  id: number;
  country_id: number;
  name: string;
  hero_image: string | null;
  hero_r2_url: string | null;
};

type SqliteVenue = {
  id: number;
  suburb_id: number | null;
  google_map_id: string;
  name: string;
  lat: number;
  lng: number;
  website_uri: string | null;
  hero_image: string | null;
  hero_r2_url: string | null;
  blurb: string | null;
  google_rating: number | null;
  last_crawl_date: string | null;
  last_update: string | null;
  status: string;
  json: string;
};

/** Public CDN URL for the website; falls back to source URL if R2 upload is missing. */
function venueHeroImageForPostgres(venueRow: SqliteVenue): string | null {
  const r2 = venueRow.hero_r2_url?.trim();
  if (r2) {
    return r2;
  }
  const source = venueRow.hero_image?.trim();
  return source || null;
}

/** Public CDN URL for the website; falls back to source URL if R2 upload is missing. */
function suburbHeroImageForPostgres(suburbRow: SqliteSuburb): string | null {
  const r2 = suburbRow.hero_r2_url?.trim();
  if (r2) {
    return r2;
  }
  const source = suburbRow.hero_image?.trim();
  return source || null;
}

/** Public CDN URL for the website; falls back to source URL if R2 upload is missing. */
function regionHeroImageForPostgres(
  regionRow: SqliteGeographicRegion,
): string | null {
  const r2 = regionRow.hero_r2_url?.trim();
  if (r2) {
    return r2;
  }
  const source = regionRow.hero_image?.trim();
  return source || null;
}

type SqliteVenueLinks = {
  venue_id: number;
  whats_on: string | null;
  instagram: string | null;
  facebook: string | null;
};

type SyncMode = "all" | "incremental";

function parseArgs(argv: string[]): {
  sqlitePath: string | undefined;
  syncAll: boolean;
} {
  let sqlitePath = process.env.SQLITE_PATH || undefined;
  let syncAll = false;

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--sqlite-path" && argv[i + 1]) {
      sqlitePath = argv[i + 1];
      i += 1;
    } else if (arg === "--all") {
      syncAll = true;
    }
  }

  return { sqlitePath, syncAll };
}

function resolveSqlitePath(rawPath: string | undefined): string {
  if (!rawPath?.trim()) {
    throw new Error(
      "SQLITE_PATH is required. Set it in .env.local or pass --sqlite-path.",
    );
  }

  const expanded = rawPath.startsWith("~")
    ? path.join(homedir(), rawPath.slice(1))
    : rawPath;

  return expanded;
}

function resolveRegionsCatalogPath(): string {
  const candidates = [
    path.resolve(process.cwd(), "data", "regions.json"),
    path.resolve(process.cwd(), "..", "data", "regions.json"),
  ];
  for (const candidate of candidates) {
    if (existsSync(candidate)) {
      return candidate;
    }
  }
  throw new Error(
    `regions.json not found. Tried:\n${candidates.map((p) => `  ${p}`).join("\n")}`,
  );
}

/**
 * Region names with status "live" get a full suburb catalog and every non-broken
 * venue (with or without deals). Other regions only sync venues that have at
 * least one approved deal — and those venues' suburbs — not every suburb.
 */
function loadLiveRegionNames(): Set<string> {
  const catalogPath = resolveRegionsCatalogPath();
  const entries = JSON.parse(
    readFileSync(catalogPath, "utf8"),
  ) as RegionCatalogEntry[];
  if (!Array.isArray(entries)) {
    throw new Error(`Invalid regions catalog at ${catalogPath}`);
  }
  return new Set(
    entries
      .filter((entry) => entry.status === "live")
      .map((entry) => entry.name),
  );
}

function parseJsonColumn(raw: string): unknown {
  try {
    return JSON.parse(raw);
  } catch {
    return { raw };
  }
}

function parseTimestamp(raw: string | null): Date | null {
  if (!raw) {
    return null;
  }

  const parsed = new Date(raw);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function sydneyToday(): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "Australia/Sydney",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(new Date());
}

async function main() {
  const { sqlitePath: rawPath, syncAll } = parseArgs(process.argv.slice(2));
  const sqlitePath = resolveSqlitePath(rawPath);
  const databaseUrl = process.env.DATABASE_URL;

  if (!databaseUrl) {
    throw new Error("DATABASE_URL is not set");
  }

  const sqlite = new Database(sqlitePath, { readonly: true });
  const pgClient = postgres(databaseUrl, { max: 1 });
  const db = drizzle(pgClient, { schema });

  const lastSuccessful = await db
    .select({ finishedAt: schema.syncRun.finishedAt })
    .from(schema.syncRun)
    .where(isNotNull(schema.syncRun.finishedAt))
    .orderBy(desc(schema.syncRun.finishedAt))
    .limit(1);

  const watermark = lastSuccessful[0]?.finishedAt ?? null;
  const useIncremental = !syncAll && watermark != null;
  const mode: SyncMode = useIncremental ? "incremental" : "all";

  const [syncRunRow] = await db
    .insert(schema.syncRun)
    .values({
      startedAt: new Date(),
      mode,
      venuesSynced: 0,
      dealsSynced: 0,
      suburbsSynced: 0,
    })
    .returning({ id: schema.syncRun.id });

  let venuesSynced = 0;
  let dealsSynced = 0;
  let bulkSuburbsSynced = 0;
  let venueSuburbsSynced = 0;
  let prunedEmptySuburbs = 0;
  let prunedIneligibleVenues = 0;
  const syncedSuburbKeys = new Set<string>();
  const today = sydneyToday();
  const liveRegionNames = loadLiveRegionNames();

  try {
    function suburbKey(name: string, postcode: string | null): string {
      return `${name}\u0000${postcode ?? ""}`;
    }

    const sqliteCountries = sqlite
      .prepare("SELECT * FROM country ORDER BY id")
      .all() as SqliteCountry[];

    const countryIdBySqliteId = new Map<number, number>();
    for (const countryRow of sqliteCountries) {
      const [upsertedCountry] = await db
        .insert(schema.country)
        .values({
          name: countryRow.name,
          iso3: countryRow.iso3,
        })
        .onConflictDoUpdate({
          target: schema.country.iso3,
          set: {
            name: countryRow.name,
          },
        })
        .returning({ id: schema.country.id });
      countryIdBySqliteId.set(countryRow.id, upsertedCountry.id);
    }

    const sqliteRegions = sqlite
      .prepare("SELECT * FROM geographic_region ORDER BY id")
      .all() as SqliteGeographicRegion[];

    const regionIdBySqliteId = new Map<number, number>();
    const nonLivePgRegionIds: number[] = [];
    for (const regionRow of sqliteRegions) {
      const pgCountryId = countryIdBySqliteId.get(regionRow.country_id);
      if (pgCountryId == null) {
        throw new Error(
          `Geographic region "${regionRow.name}" references missing country id ${regionRow.country_id}`,
        );
      }

      const [upsertedRegion] = await db
        .insert(schema.geographicRegion)
        .values({
          countryId: pgCountryId,
          name: regionRow.name,
          heroImage: regionHeroImageForPostgres(regionRow),
        })
        .onConflictDoUpdate({
          target: [
            schema.geographicRegion.countryId,
            schema.geographicRegion.name,
          ],
          set: {
            name: regionRow.name,
            heroImage: regionHeroImageForPostgres(regionRow),
          },
        })
        .returning({ id: schema.geographicRegion.id });
      regionIdBySqliteId.set(regionRow.id, upsertedRegion.id);
      if (!liveRegionNames.has(regionRow.name)) {
        nonLivePgRegionIds.push(upsertedRegion.id);
      }
    }

    const liveSqliteRegionIds = sqliteRegions
      .filter((region) => liveRegionNames.has(region.name))
      .map((region) => region.id);

    const liveRegionPlaceholders =
      liveSqliteRegionIds.length === 0
        ? ""
        : liveSqliteRegionIds.map(() => "?").join(", ");

    const incrementalClause = useIncremental
      ? "AND datetime(v.last_update) > datetime(?)"
      : "";
    const incrementalParams = useIncremental
      ? [watermark!.toISOString()]
      : [];

    // Live regions: every non-broken venue (including venues with no approved deals).
    const liveVenueRows =
      liveSqliteRegionIds.length === 0
        ? []
        : (sqlite
            .prepare(
              `
              SELECT v.*
              FROM venue v
              INNER JOIN suburb s ON s.id = v.suburb_id
              WHERE v.status != 'broken'
                AND s.region_id IN (${liveRegionPlaceholders})
                ${incrementalClause}
              ORDER BY v.id
              `,
            )
            .all(
              ...liveSqliteRegionIds,
              ...incrementalParams,
            ) as SqliteVenue[]);

    // Non-live / unassigned regions: only venues with at least one approved deal.
    const nonLiveRegionClause =
      liveSqliteRegionIds.length === 0
        ? ""
        : `AND (s.region_id IS NULL OR s.region_id NOT IN (${liveRegionPlaceholders}))`;
    const nonLiveVenueRows = sqlite
      .prepare(
        `
        SELECT DISTINCT v.*
        FROM venue v
        INNER JOIN suburb s ON s.id = v.suburb_id
        INNER JOIN deal d ON d.venue_id = v.id
        WHERE v.status != 'broken'
          AND d.status = 'approved'
          ${nonLiveRegionClause}
          ${incrementalClause}
        ORDER BY v.id
        `,
      )
      .all(
        ...liveSqliteRegionIds,
        ...incrementalParams,
      ) as SqliteVenue[];

    const venueRowsById = new Map<number, SqliteVenue>();
    for (const row of liveVenueRows) {
      venueRowsById.set(row.id, row);
    }
    for (const row of nonLiveVenueRows) {
      venueRowsById.set(row.id, row);
    }
    const venueRows = [...venueRowsById.values()].sort((a, b) => a.id - b.id);

    const liveEligibleIds =
      liveSqliteRegionIds.length === 0
        ? []
        : (sqlite
            .prepare(
              `
              SELECT v.google_map_id
              FROM venue v
              INNER JOIN suburb s ON s.id = v.suburb_id
              WHERE v.status != 'broken'
                AND s.region_id IN (${liveRegionPlaceholders})
              `,
            )
            .all(...liveSqliteRegionIds) as { google_map_id: string }[]);

    const nonLiveEligibleIds = sqlite
      .prepare(
        `
        SELECT DISTINCT v.google_map_id
        FROM venue v
        INNER JOIN suburb s ON s.id = v.suburb_id
        INNER JOIN deal d ON d.venue_id = v.id
        WHERE v.status != 'broken'
          AND d.status = 'approved'
          ${nonLiveRegionClause}
        `,
      )
      .all(...liveSqliteRegionIds) as { google_map_id: string }[];

    const eligibleGoogleMapIds = new Set(
      [...liveEligibleIds, ...nonLiveEligibleIds].map(
        (row) => row.google_map_id,
      ),
    );

    async function upsertSuburb(
      tx: Parameters<Parameters<typeof db.transaction>[0]>[0],
      suburbRow: SqliteSuburb,
    ): Promise<number> {
      const heroImage = suburbHeroImageForPostgres(suburbRow);
      const regionId =
        suburbRow.region_id != null
          ? (regionIdBySqliteId.get(suburbRow.region_id) ?? null)
          : null;
      const [upsertedSuburb] = await tx
        .insert(schema.suburb)
        .values({
          name: suburbRow.name,
          postcode: suburbRow.postcode,
          state: suburbRow.state,
          lat: suburbRow.lat,
          lng: suburbRow.lng,
          sqkm: suburbRow.sqkm,
          population: suburbRow.population,
          heroImage,
          regionId,
        })
        .onConflictDoUpdate({
          target: [schema.suburb.name, schema.suburb.postcode],
          set: {
            name: suburbRow.name,
            postcode: suburbRow.postcode,
            state: suburbRow.state,
            lat: suburbRow.lat,
            lng: suburbRow.lng,
            sqkm: suburbRow.sqkm,
            population: suburbRow.population,
            heroImage,
            regionId,
          },
        })
        .returning({ id: schema.suburb.id });

      return upsertedSuburb.id;
    }

    const regionSuburbs =
      liveSqliteRegionIds.length === 0
        ? []
        : (sqlite
            .prepare(
              `SELECT * FROM suburb WHERE region_id IN (${liveRegionPlaceholders}) ORDER BY id`,
            )
            .all(...liveSqliteRegionIds) as SqliteSuburb[]);

    for (const suburbRow of regionSuburbs) {
      await db.transaction(async (tx) => {
        await upsertSuburb(tx, suburbRow);
      });
      syncedSuburbKeys.add(suburbKey(suburbRow.name, suburbRow.postcode));
      bulkSuburbsSynced += 1;
    }

    for (const venueRow of venueRows) {
      await db.transaction(async (tx) => {
        let suburbId: number | null = null;

        if (venueRow.suburb_id != null) {
          const suburbRow = sqlite
            .prepare("SELECT * FROM suburb WHERE id = ?")
            .get(venueRow.suburb_id) as SqliteSuburb | undefined;

          if (suburbRow) {
            suburbId = await upsertSuburb(tx, suburbRow);
            const key = suburbKey(suburbRow.name, suburbRow.postcode);
            if (!syncedSuburbKeys.has(key)) {
              venueSuburbsSynced += 1;
            }
            syncedSuburbKeys.add(key);
          }
        }

        const venueJson = parseJsonColumn(venueRow.json);
        const heroImage = venueHeroImageForPostgres(venueRow);

        const [upsertedVenue] = await tx
          .insert(schema.venue)
          .values({
            suburbId,
            googleMapId: venueRow.google_map_id,
            name: venueRow.name,
            lat: venueRow.lat,
            lng: venueRow.lng,
            websiteUri: venueRow.website_uri,
            heroImage,
            blurb: venueRow.blurb,
            googleRating: venueRow.google_rating,
            lastCrawlDate: parseTimestamp(venueRow.last_crawl_date),
            json: venueJson,
            syncedAt: new Date(),
          })
          .onConflictDoUpdate({
            target: schema.venue.googleMapId,
            set: {
              suburbId,
              name: venueRow.name,
              lat: venueRow.lat,
              lng: venueRow.lng,
              websiteUri: venueRow.website_uri,
              heroImage,
              blurb: venueRow.blurb,
              googleRating: venueRow.google_rating,
              lastCrawlDate: parseTimestamp(venueRow.last_crawl_date),
              json: venueJson,
              syncedAt: new Date(),
            },
          })
          .returning({ id: schema.venue.id });

        const venueId = upsertedVenue.id;

        const linksRow = sqlite
          .prepare("SELECT * FROM venue_links WHERE venue_id = ?")
          .get(venueRow.id) as SqliteVenueLinks | undefined;

        if (linksRow) {
          await tx
            .insert(schema.venueLinks)
            .values({
              venueId,
              whatsOn: linksRow.whats_on,
              instagram: linksRow.instagram,
              facebook: linksRow.facebook,
            })
            .onConflictDoUpdate({
              target: schema.venueLinks.venueId,
              set: {
                whatsOn: linksRow.whats_on,
                instagram: linksRow.instagram,
                facebook: linksRow.facebook,
              },
            });
        }

        const approvedDeals = sqlite
          .prepare(
            "SELECT * FROM deal WHERE venue_id = ? AND status = 'approved' ORDER BY id",
          )
          .all(venueRow.id) as SqliteDeal[];

        const schedulesByDealId = new Map<number, SqliteDealSchedule[]>();
        for (const dealRow of approvedDeals) {
          const schedules = sqlite
            .prepare("SELECT * FROM deal_schedule WHERE deal_id = ? ORDER BY id")
            .all(dealRow.id) as SqliteDealSchedule[];
          schedulesByDealId.set(dealRow.id, schedules);
        }

        // Deals are upserted by SQLite deal.id -> Postgres source_deal_id so
        // Postgres deal.id (and browser favourites) survive subsequent syncs.
        dealsSynced += await syncVenueDeals(
          tx,
          venueId,
          approvedDeals,
          schedulesByDealId,
          today,
          venueJson,
        );

        venuesSynced += 1;
      });
    }

    if (!useIncremental) {
      const pgVenues = await db
        .select({
          id: schema.venue.id,
          googleMapId: schema.venue.googleMapId,
        })
        .from(schema.venue);
      const ineligibleIds = pgVenues
        .filter((row) => !eligibleGoogleMapIds.has(row.googleMapId))
        .map((row) => row.id);
      if (ineligibleIds.length > 0) {
        const pruned = await db
          .delete(schema.venue)
          .where(inArray(schema.venue.id, ineligibleIds))
          .returning({ id: schema.venue.id });
        prunedIneligibleVenues = pruned.length;
      }
    }

    if (nonLivePgRegionIds.length > 0) {
      const pruned = await db
        .delete(schema.suburb)
        .where(
          and(
            inArray(schema.suburb.regionId, nonLivePgRegionIds),
            notExists(
              db
                .select({ one: sql`1` })
                .from(schema.venue)
                .where(eq(schema.venue.suburbId, schema.suburb.id)),
            ),
          ),
        )
        .returning({ id: schema.suburb.id });
      prunedEmptySuburbs = pruned.length;
    }

    await db
      .update(schema.syncRun)
      .set({
        finishedAt: new Date(),
        venuesSynced,
        dealsSynced,
        suburbsSynced: syncedSuburbKeys.size,
      })
      .where(eq(schema.syncRun.id, syncRunRow.id));
  } finally {
    sqlite.close();
    await pgClient.end();
  }

  console.log("Sync complete");
  console.log(`  SQLite: ${sqlitePath}`);
  console.log(`  Mode: ${mode}`);
  if (useIncremental) {
    console.log(`  Watermark: ${watermark!.toISOString()}`);
  } else if (!syncAll && watermark == null) {
    console.log("  Watermark: none (first sync — synced all venues)");
  }
  console.log(
    `  Live regions: ${[...liveRegionNames].sort().join(", ") || "(none)"}`,
  );
  console.log(`  Suburbs synced: ${syncedSuburbKeys.size}`);
  console.log(`    Bulk (live regions): ${bulkSuburbsSynced}`);
  console.log(`    Via venues (non-bulk): ${venueSuburbsSynced}`);
  console.log(`  Empty non-live suburbs pruned: ${prunedEmptySuburbs}`);
  if (!useIncremental) {
    console.log(`  Ineligible venues pruned: ${prunedIneligibleVenues}`);
  }
  console.log(`  Venues synced: ${venuesSynced}`);
  console.log(`  Deals synced: ${dealsSynced}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
