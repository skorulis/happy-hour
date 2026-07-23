import { loadScriptEnv } from "../load-script-env";

loadScriptEnv();
import Database from "better-sqlite3";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import path from "node:path";

const REQUIRED_REGION_NAMES = [
  "Sydney",
  "Melbourne",
  "Brisbane",
  "Perth",
  "Adelaide",
  "Darwin",
  "Sunshine Coast",
  "Regional NSW",
] as const;

/** ABS Greater Capital City Statistical Areas → region name. */
const GREATER_STATISTIC_AREA_REGIONS: Record<string, string> = {
  "Greater Sydney": "Sydney",
  "Greater Melbourne": "Melbourne",
  "Greater Brisbane": "Brisbane",
  "Greater Perth": "Perth",
  "Greater Adelaide": "Adelaide",
  "Greater Darwin": "Darwin",
};

type SuburbNameOverride = {
  sourceName: string;
  postcode: string;
  state: string;
  canonicalName: string;
};

// Distinguish the Sydney CBD suburb from the Sydney geographic region.
const SUBURB_NAME_OVERRIDES: SuburbNameOverride[] = [
  {
    sourceName: "Sydney",
    postcode: "2000",
    state: "NSW",
    canonicalName: "Sydney CBD",
  },
];

type AustralianSuburb = {
  suburb: string;
  postcode: number;
  state: string;
  lat: number;
  lng: number;
  sqkm: number;
  population: number;
  statistic_area: string;
  local_goverment_area: string;
};

type SuburbsFile = {
  data: AustralianSuburb[];
};

type DbSuburb = {
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
};

type ImportStats = {
  jsonUnique: number;
  jsonDuplicates: number;
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
    process.env.SUBURBS_JSON_PATH ||
    "~/Downloads/australian-suburbs/data/suburbs.json";
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

function ensureSuburbPopulationColumn(db: Database.Database): void {
  const columns = db.prepare("PRAGMA table_info(suburb)").all() as Array<{
    name: string;
  }>;
  if (columns.some((column) => column.name === "population")) {
    return;
  }
  db.exec("ALTER TABLE suburb ADD COLUMN population INTEGER");
}

function canonicalSuburbName(
  name: string,
  postcode: string,
  state: string,
): string {
  const override = SUBURB_NAME_OVERRIDES.find(
    (entry) =>
      entry.sourceName === name &&
      entry.postcode === postcode &&
      entry.state === state,
  );
  return override?.canonicalName ?? name;
}

function loadCatalog(jsonPath: string): {
  byKey: Map<string, AustralianSuburb>;
  duplicates: number;
} {
  const raw = readFileSync(jsonPath, "utf8");
  const parsed = JSON.parse(raw) as SuburbsFile;
  const byKey = new Map<string, AustralianSuburb>();
  let duplicates = 0;

  for (const entry of parsed.data) {
    const name = entry.suburb.trim();
    const postcode = String(entry.postcode);
    const key = suburbKey(name, postcode);

    if (byKey.has(key)) {
      duplicates += 1;
      continue;
    }

    byKey.set(key, entry);
  }

  return { byKey, duplicates };
}

function loadRegionIdsByName(db: Database.Database): Map<string, number> {
  const rows = db
    .prepare("SELECT id, name FROM geographic_region")
    .all() as Array<{ id: number; name: string }>;

  const byName = new Map(rows.map((row) => [row.name, row.id]));

  for (const name of REQUIRED_REGION_NAMES) {
    if (!byName.has(name)) {
      throw new Error(
        `Missing geographic region "${name}". Open DealScraper once so default regions are seeded.`,
      );
    }
  }

  return byName;
}

function resolveRegionId(
  entry: AustralianSuburb,
  regionIdsByName: Map<string, number>,
): number | null {
  // Prefer Sunshine Coast LGA over Greater Brisbane for the rare overlap.
  if (entry.local_goverment_area === "Sunshine Coast (Regional Council)") {
    return regionIdsByName.get("Sunshine Coast") ?? null;
  }
  const greaterRegion = GREATER_STATISTIC_AREA_REGIONS[entry.statistic_area];
  if (greaterRegion) {
    return regionIdsByName.get(greaterRegion) ?? null;
  }
  if (entry.state === "NSW") {
    return regionIdsByName.get("Regional NSW") ?? null;
  }
  return null;
}

function hasMissingFields(
  existing: DbSuburb,
  entry: AustralianSuburb,
  regionId: number | null,
): boolean {
  return (
    (existing.state == null && entry.state != null) ||
    (existing.lat == null && entry.lat != null) ||
    (existing.lng == null && entry.lng != null) ||
    (existing.sqkm == null && entry.sqkm != null) ||
    (existing.population == null && entry.population != null) ||
    (existing.statistic_area == null && entry.statistic_area != null) ||
    (existing.region_id == null && regionId != null)
  );
}

function findExistingSuburb(
  findStmt: Database.Statement<
    [string, string | null, string | null],
    DbSuburb | undefined
  >,
  sourceName: string,
  canonicalName: string,
  postcode: string,
): DbSuburb | undefined {
  const byCanonical = findStmt.get(canonicalName, postcode, postcode);
  if (byCanonical) {
    return byCanonical;
  }
  if (canonicalName !== sourceName) {
    return findStmt.get(sourceName, postcode, postcode);
  }
  return undefined;
}

function needsUpdate(
  existing: DbSuburb,
  entry: AustralianSuburb,
  regionId: number | null,
  canonicalName: string,
): boolean {
  return (
    existing.name !== canonicalName ||
    hasMissingFields(existing, entry, regionId)
  );
}

function upsertCatalog(
  db: Database.Database,
  catalog: Map<string, AustralianSuburb>,
  regionIdsByName: Map<string, number>,
  dryRun: boolean,
): ImportStats {
  const stats: ImportStats = {
    jsonUnique: catalog.size,
    jsonDuplicates: 0,
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
    SELECT id, name, postcode, state, lat, lng, sqkm, population, statistic_area, region_id
    FROM suburb
    WHERE name = ? AND (
      (postcode IS NULL AND ? IS NULL) OR postcode = ?
    )
    `,
  );

  const insertStmt = db.prepare(
    `
    INSERT INTO suburb (name, postcode, state, lat, lng, sqkm, population, statistic_area, region_id)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `,
  );

  const updateStmt = db.prepare(
    `
    UPDATE suburb
    SET name = ?,
        state = COALESCE(state, ?),
        lat = COALESCE(lat, ?),
        lng = COALESCE(lng, ?),
        sqkm = COALESCE(sqkm, ?),
        population = COALESCE(population, ?),
        statistic_area = COALESCE(statistic_area, ?),
        region_id = COALESCE(region_id, ?)
    WHERE id = ?
    `,
  );

  const renameSydneySuburbStmt = db.prepare(`
    UPDATE suburb
    SET name = 'Sydney CBD'
    WHERE name = 'Sydney' AND postcode = '2000' AND state = 'NSW'
  `);

  const run = (fn: () => void) => {
    if (!dryRun) {
      fn();
    }
  };

  const upsertAll = db.transaction(() => {
    for (const entry of catalog.values()) {
      const sourceName = entry.suburb.trim();
      const postcode = String(entry.postcode);
      const canonicalName = canonicalSuburbName(
        sourceName,
        postcode,
        entry.state,
      );
      const regionId = resolveRegionId(entry, regionIdsByName);
      const existing = findExistingSuburb(
        findStmt,
        sourceName,
        canonicalName,
        postcode,
      );

      if (!existing) {
        stats.inserted += 1;
        if (regionId != null) {
          stats.regionsAssigned += 1;
        }
        run(() => {
          insertStmt.run(
            canonicalName,
            postcode,
            entry.state,
            entry.lat,
            entry.lng,
            entry.sqkm,
            entry.population,
            entry.statistic_area,
            regionId,
          );
        });
        continue;
      }

      if (!needsUpdate(existing, entry, regionId, canonicalName)) {
        stats.unchanged += 1;
        continue;
      }

      stats.updated += 1;
      if (existing.region_id == null && regionId != null) {
        stats.regionsAssigned += 1;
      }
      run(() => {
        updateStmt.run(
          canonicalName,
          entry.state,
          entry.lat,
          entry.lng,
          entry.sqkm,
          entry.population,
          entry.statistic_area,
          regionId,
          existing.id,
        );
      });
    }

    run(() => {
      renameSydneySuburbStmt.run();
    });
  });

  upsertAll();
  return stats;
}

async function main() {
  const { sqlitePath: rawSqlitePath, jsonPath: rawJsonPath, dryRun } =
    parseArgs(process.argv.slice(2));
  const sqlitePath = resolveSqlitePath(rawSqlitePath);
  const jsonPath = expandPath(rawJsonPath!);

  const { byKey, duplicates } = loadCatalog(jsonPath);
  const db = new Database(sqlitePath);

  try {
    ensureSuburbPopulationColumn(db);

    const existingCount = (
      db.prepare("SELECT COUNT(*) AS count FROM suburb").get() as {
        count: number;
      }
    ).count;

    const regionIdsByName = loadRegionIdsByName(db);
    const stats = upsertCatalog(db, byKey, regionIdsByName, dryRun);
    stats.jsonDuplicates = duplicates;

    console.log(dryRun ? "Dry run complete" : "Suburb import complete");
    console.log(`  SQLite: ${sqlitePath}`);
    console.log(`  JSON: ${jsonPath}`);
    console.log(`  JSON entries (unique): ${stats.jsonUnique}`);
    if (stats.jsonDuplicates > 0) {
      console.log(
        `  JSON duplicate name/postcode pairs skipped: ${stats.jsonDuplicates}`,
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
