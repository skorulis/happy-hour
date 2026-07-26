import { loadScriptEnv } from "../load-script-env";

loadScriptEnv();
import Database from "better-sqlite3";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import path from "node:path";

const QUEENSTOWN_LAKES_REGION_NAME = "Queenstown Lakes";

type NzPostcodeEntry = {
  postcode: string;
  locality: string;
  region: string;
  long: string;
  lat: string;
  territory: string;
  island: string;
};

type NzSuburb = {
  name: string;
  postcode: string;
  state: string;
  lat: number;
  lng: number;
  statistic_area: string;
};

type DbSuburb = {
  id: number;
  name: string;
  postcode: string | null;
  state: string | null;
  lat: number | null;
  lng: number | null;
  statistic_area: string | null;
  country_id: number | null;
  region_id: number | null;
};

type ImportStats = {
  jsonUnique: number;
  jsonSkippedAlternates: number;
  jsonInvalidPostcodes: number;
  inserted: number;
  updated: number;
  unchanged: number;
  regionsAssigned: number;
};

function parseArgs(argv: string[]): {
  sqlitePath: string | undefined;
  jsonPath: string | undefined;
  dryRun: boolean;
} {
  let sqlitePath = process.env.SQLITE_PATH || undefined;
  let jsonPath =
    process.env.NZ_SUBURBS_JSON_PATH ||
    "~/Downloads/nz-suburbs/newzealand_postcodes.json";
  let dryRun = false;

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--sqlite-path" && argv[i + 1]) {
      sqlitePath = argv[i + 1];
      i += 1;
    } else if (arg === "--json-path" && argv[i + 1]) {
      jsonPath = argv[i + 1];
      i += 1;
    } else if (arg === "--dry-run") {
      dryRun = true;
    }
  }

  return { sqlitePath, jsonPath, dryRun };
}

function expandPath(rawPath: string): string {
  return rawPath.startsWith("~")
    ? path.join(homedir(), rawPath.slice(1))
    : rawPath;
}

function resolveSqlitePath(rawPath: string | undefined): string {
  if (!rawPath?.trim()) {
    throw new Error(
      "SQLITE_PATH is required. Set it in .env.local or pass --sqlite-path.",
    );
  }

  return expandPath(rawPath);
}

function suburbKey(name: string, postcode: string | null): string {
  return `${name}\u0000${postcode ?? ""}`;
}

/** Group key: same locality + first two postcode digits = one suburb. */
function localityPrefixKey(name: string, postcode: string): string {
  return `${name}\u0000${postcode.slice(0, 2)}`;
}

function thirdDigit(postcode: string): number {
  return Number(postcode[2]);
}

function isQueenstownLakesTerritory(territory: string): boolean {
  return (
    territory === "Queenstown-Lakes District" ||
    territory === "Queenstown-Lakes"
  );
}

function loadNzCountryId(db: Database.Database): number {
  const row = db
    .prepare("SELECT id FROM country WHERE iso3 = 'NZL'")
    .get() as { id: number } | undefined;

  if (!row) {
    throw new Error(
      "Missing country NZL. Open DealScraper once so default countries are seeded.",
    );
  }

  return row.id;
}

function loadQueenstownLakesRegionId(
  db: Database.Database,
  countryId: number,
): number {
  const row = db
    .prepare(
      "SELECT id FROM geographic_region WHERE country_id = ? AND name = ?",
    )
    .get(countryId, QUEENSTOWN_LAKES_REGION_NAME) as
    | { id: number }
    | undefined;

  if (!row) {
    throw new Error(
      `Missing geographic region "${QUEENSTOWN_LAKES_REGION_NAME}". Open DealScraper once so default regions are seeded.`,
    );
  }

  return row.id;
}

function resolveRegionId(
  entry: NzSuburb,
  queenstownLakesRegionId: number,
): number | null {
  if (isQueenstownLakesTerritory(entry.statistic_area)) {
    return queenstownLakesRegionId;
  }
  return null;
}

function toNzSuburb(entry: NzPostcodeEntry, postcode: string): NzSuburb {
  return {
    name: entry.locality.trim(),
    postcode,
    state: entry.region.trim(),
    lat: Number(entry.lat),
    lng: Number(entry.long),
    statistic_area: entry.territory.trim(),
  };
}

/**
 * Prefer the postcode with the smallest 3rd digit within each
 * (locality, first-two-digits) group. Same name with different prefixes
 * (e.g. 01xx vs 79xx) stay as separate suburbs.
 */
function loadCatalog(jsonPath: string): {
  byKey: Map<string, NzSuburb>;
  skippedAlternates: number;
  invalidPostcodes: number;
} {
  const raw = readFileSync(jsonPath, "utf8");
  const parsed = JSON.parse(raw) as NzPostcodeEntry[];
  const bestByPrefix = new Map<string, NzSuburb>();
  let skippedAlternates = 0;
  let invalidPostcodes = 0;

  for (const entry of parsed) {
    const postcode = String(entry.postcode).trim();
    if (postcode.length !== 4 || !/^\d{4}$/.test(postcode)) {
      invalidPostcodes += 1;
      continue;
    }

    const name = entry.locality.trim();
    const prefixKey = localityPrefixKey(name, postcode);
    const candidate = toNzSuburb(entry, postcode);
    const existing = bestByPrefix.get(prefixKey);

    if (!existing) {
      bestByPrefix.set(prefixKey, candidate);
      continue;
    }

    const existingThird = thirdDigit(existing.postcode);
    const candidateThird = thirdDigit(candidate.postcode);
    if (
      candidateThird < existingThird ||
      (candidateThird === existingThird &&
        candidate.postcode < existing.postcode)
    ) {
      bestByPrefix.set(prefixKey, candidate);
    }
    skippedAlternates += 1;
  }

  const byKey = new Map<string, NzSuburb>();
  for (const suburb of bestByPrefix.values()) {
    byKey.set(suburbKey(suburb.name, suburb.postcode), suburb);
  }

  return { byKey, skippedAlternates, invalidPostcodes };
}

function hasMissingFields(
  existing: DbSuburb,
  entry: NzSuburb,
  countryId: number,
  regionId: number | null,
): boolean {
  return (
    (existing.state == null && entry.state != null) ||
    (existing.lat == null && Number.isFinite(entry.lat)) ||
    (existing.lng == null && Number.isFinite(entry.lng)) ||
    (existing.statistic_area == null && entry.statistic_area != null) ||
    (existing.country_id == null && countryId != null) ||
    (existing.region_id == null && regionId != null)
  );
}

function needsUpdate(
  existing: DbSuburb,
  entry: NzSuburb,
  countryId: number,
  regionId: number | null,
): boolean {
  return hasMissingFields(existing, entry, countryId, regionId);
}

function upsertCatalog(
  db: Database.Database,
  catalog: Map<string, NzSuburb>,
  countryId: number,
  queenstownLakesRegionId: number,
  dryRun: boolean,
): ImportStats {
  const stats: ImportStats = {
    jsonUnique: catalog.size,
    jsonSkippedAlternates: 0,
    jsonInvalidPostcodes: 0,
    inserted: 0,
    updated: 0,
    unchanged: 0,
    regionsAssigned: 0,
  };

  const findStmt = db.prepare<
    [string, string | null, string | null],
    DbSuburb | undefined
  >(
    `
    SELECT id, name, postcode, state, lat, lng, statistic_area, country_id, region_id
    FROM suburb
    WHERE name = ? AND (
      (postcode IS NULL AND ? IS NULL) OR postcode = ?
    )
    `,
  );

  const insertStmt = db.prepare(
    `
    INSERT INTO suburb (name, postcode, state, lat, lng, statistic_area, country_id, region_id)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `,
  );

  const updateStmt = db.prepare(
    `
    UPDATE suburb
    SET state = COALESCE(state, ?),
        lat = COALESCE(lat, ?),
        lng = COALESCE(lng, ?),
        statistic_area = COALESCE(statistic_area, ?),
        country_id = COALESCE(country_id, ?),
        region_id = COALESCE(region_id, ?)
    WHERE id = ?
    `,
  );

  const run = (fn: () => void) => {
    if (!dryRun) {
      fn();
    }
  };

  const upsertAll = db.transaction(() => {
    for (const entry of catalog.values()) {
      const regionId = resolveRegionId(entry, queenstownLakesRegionId);
      const existing = findStmt.get(entry.name, entry.postcode, entry.postcode);

      if (!existing) {
        stats.inserted += 1;
        if (regionId != null) {
          stats.regionsAssigned += 1;
        }
        run(() => {
          insertStmt.run(
            entry.name,
            entry.postcode,
            entry.state,
            entry.lat,
            entry.lng,
            entry.statistic_area,
            countryId,
            regionId,
          );
        });
        continue;
      }

      if (!needsUpdate(existing, entry, countryId, regionId)) {
        stats.unchanged += 1;
        continue;
      }

      stats.updated += 1;
      if (existing.region_id == null && regionId != null) {
        stats.regionsAssigned += 1;
      }
      run(() => {
        updateStmt.run(
          entry.state,
          entry.lat,
          entry.lng,
          entry.statistic_area,
          countryId,
          regionId,
          existing.id,
        );
      });
    }
  });

  upsertAll();
  return stats;
}

async function main() {
  const { sqlitePath: rawSqlitePath, jsonPath: rawJsonPath, dryRun } =
    parseArgs(process.argv.slice(2));
  const sqlitePath = resolveSqlitePath(rawSqlitePath);
  const jsonPath = expandPath(rawJsonPath!);

  const { byKey, skippedAlternates, invalidPostcodes } = loadCatalog(jsonPath);
  const db = new Database(sqlitePath);

  try {
    const existingCount = (
      db.prepare("SELECT COUNT(*) AS count FROM suburb").get() as {
        count: number;
      }
    ).count;

    const countryId = loadNzCountryId(db);
    const queenstownLakesRegionId = loadQueenstownLakesRegionId(db, countryId);
    const stats = upsertCatalog(
      db,
      byKey,
      countryId,
      queenstownLakesRegionId,
      dryRun,
    );
    stats.jsonSkippedAlternates = skippedAlternates;
    stats.jsonInvalidPostcodes = invalidPostcodes;

    console.log(dryRun ? "Dry run complete" : "NZ suburb import complete");
    console.log(`  SQLite: ${sqlitePath}`);
    console.log(`  JSON: ${jsonPath}`);
    console.log(`  JSON entries (unique): ${stats.jsonUnique}`);
    console.log(
      `  JSON alternate postcodes skipped: ${stats.jsonSkippedAlternates}`,
    );
    if (stats.jsonInvalidPostcodes > 0) {
      console.log(
        `  JSON invalid postcodes skipped: ${stats.jsonInvalidPostcodes}`,
      );
    }
    console.log(`  Existing suburbs before import: ${existingCount}`);
    console.log(`  Inserted: ${stats.inserted}`);
    console.log(`  Updated: ${stats.updated}`);
    console.log(`  Unchanged: ${stats.unchanged}`);
    console.log(`  Regions assigned: ${stats.regionsAssigned}`);
  } finally {
    db.close();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
