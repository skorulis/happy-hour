import { loadScriptEnv } from "../load-script-env";

loadScriptEnv();
import Database from "better-sqlite3";
import { eq } from "drizzle-orm";
import { drizzle } from "drizzle-orm/postgres-js";
import { homedir } from "node:os";
import path from "node:path";
import postgres from "postgres";
import * as schema from "../db/schema";

type SqliteSuburb = {
  id: number;
  name: string;
  postcode: string | null;
  state: string | null;
  lat: number | null;
  lng: number | null;
  sqkm: number | null;
  statistic_area: string | null;
};

const GREATER_SYDNEY_STATISTIC_AREA = "Greater Sydney";

type SqliteVenue = {
  id: number;
  suburb_id: number | null;
  google_map_id: string;
  name: string;
  lat: number;
  lng: number;
  website_uri: string | null;
  hero_image: string | null;
  blurb: string | null;
  last_crawl_date: string | null;
  json: string;
};

type SqliteVenueLinks = {
  venue_id: number;
  whats_on: string | null;
  instagram: string | null;
  facebook: string | null;
};

type SqliteDeal = {
  id: number;
  venue_id: number;
  title: string | null;
  creative_url: string | null;
  source_url: string | null;
  details: string | null;
  conditions: string | null;
};

type SqliteDealSchedule = {
  id: number;
  deal_id: number;
  day_of_week: number;
  start_minute: number;
  end_minute: number;
};

function parseArgs(argv: string[]): { sqlitePath: string | undefined } {
  let sqlitePath = process.env.SQLITE_PATH || undefined;

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--sqlite-path" && argv[i + 1]) {
      sqlitePath = argv[i + 1];
      i += 1;
    }
  }

  return { sqlitePath };
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

async function main() {
  const { sqlitePath: rawPath } = parseArgs(process.argv.slice(2));
  const sqlitePath = resolveSqlitePath(rawPath);
  const databaseUrl = process.env.DATABASE_URL;

  if (!databaseUrl) {
    throw new Error("DATABASE_URL is not set");
  }

  const sqlite = new Database(sqlitePath, { readonly: true });
  const pgClient = postgres(databaseUrl, { max: 1 });
  const db = drizzle(pgClient, { schema });

  const venueRows = sqlite
    .prepare(
      `
      SELECT DISTINCT v.*
      FROM venue v
      INNER JOIN deal d ON d.venue_id = v.id
      WHERE d.status = 'approved'
      ORDER BY v.id
      `,
    )
    .all() as SqliteVenue[];

  let venuesSynced = 0;
  let dealsInserted = 0;
  const syncedSuburbKeys = new Set<string>();

  function suburbKey(name: string, postcode: string | null): string {
    return `${name}\u0000${postcode ?? ""}`;
  }

  async function upsertSuburb(
    tx: Parameters<Parameters<typeof db.transaction>[0]>[0],
    suburbRow: SqliteSuburb,
  ): Promise<number> {
    const [upsertedSuburb] = await tx
      .insert(schema.suburb)
      .values({
        name: suburbRow.name,
        postcode: suburbRow.postcode,
        state: suburbRow.state,
        lat: suburbRow.lat,
        lng: suburbRow.lng,
        sqkm: suburbRow.sqkm,
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
        },
      })
      .returning({ id: schema.suburb.id });

    return upsertedSuburb.id;
  }

  const greaterSydneySuburbs = sqlite
    .prepare(
      "SELECT * FROM suburb WHERE statistic_area = ? ORDER BY id",
    )
    .all(GREATER_SYDNEY_STATISTIC_AREA) as SqliteSuburb[];

  for (const suburbRow of greaterSydneySuburbs) {
    await db.transaction(async (tx) => {
      await upsertSuburb(tx, suburbRow);
    });
    syncedSuburbKeys.add(suburbKey(suburbRow.name, suburbRow.postcode));
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
          syncedSuburbKeys.add(suburbKey(suburbRow.name, suburbRow.postcode));
        }
      }

      const [upsertedVenue] = await tx
        .insert(schema.venue)
        .values({
          suburbId,
          googleMapId: venueRow.google_map_id,
          name: venueRow.name,
          lat: venueRow.lat,
          lng: venueRow.lng,
          websiteUri: venueRow.website_uri,
          heroImage: venueRow.hero_image,
          blurb: venueRow.blurb,
          lastCrawlDate: parseTimestamp(venueRow.last_crawl_date),
          json: parseJsonColumn(venueRow.json),
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
            heroImage: venueRow.hero_image,
            blurb: venueRow.blurb,
            lastCrawlDate: parseTimestamp(venueRow.last_crawl_date),
            json: parseJsonColumn(venueRow.json),
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

      await tx.delete(schema.deal).where(eq(schema.deal.venueId, venueId));

      const approvedDeals = sqlite
        .prepare(
          "SELECT * FROM deal WHERE venue_id = ? AND status = 'approved' ORDER BY id",
        )
        .all(venueRow.id) as SqliteDeal[];

      for (const dealRow of approvedDeals) {
        const [insertedDeal] = await tx
          .insert(schema.deal)
          .values({
            venueId,
            title: dealRow.title,
            imageUrl: dealRow.creative_url,
            sourceUrl: dealRow.source_url,
            details: dealRow.details,
            conditions: dealRow.conditions,
            syncedAt: new Date(),
          })
          .returning({ id: schema.deal.id });

        const schedules = sqlite
          .prepare("SELECT * FROM deal_schedule WHERE deal_id = ? ORDER BY id")
          .all(dealRow.id) as SqliteDealSchedule[];

        if (schedules.length > 0) {
          await tx.insert(schema.dealSchedule).values(
            schedules.map((schedule) => ({
              dealId: insertedDeal.id,
              dayOfWeek: schedule.day_of_week,
              startMinute: schedule.start_minute,
              endMinute: schedule.end_minute,
            })),
          );
        }

        dealsInserted += 1;
      }

      venuesSynced += 1;
    });
  }

  sqlite.close();
  await pgClient.end();

  console.log("Sync complete");
  console.log(`  SQLite: ${sqlitePath}`);
  console.log(`  Suburbs synced: ${syncedSuburbKeys.size}`);
  console.log(`  Venues synced: ${venuesSynced}`);
  console.log(`  Deals inserted: ${dealsInserted}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
