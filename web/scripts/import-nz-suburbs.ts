import { loadScriptEnv } from "../load-script-env";

loadScriptEnv();
import Database from "better-sqlite3";
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import path from "node:path";
import { open as openShapefile } from "shapefile";

const QUEENSTOWN_LAKES_REGION_NAME = "Queenstown Lakes";
const LINZ_PLACE_TYPES = new Set(["Suburb", "Locality"]);
/** Max distance when attaching a LINZ place to a same-named postcode row. */
const LINZ_NAME_MATCH_MAX_KM = 50;

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
  postcode: string | null;
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
  shpSuburbLocality: number;
  shpMatchedExisting: number;
  shpAdded: number;
  shpSkippedDuplicates: number;
  inserted: number;
  updated: number;
  unchanged: number;
  regionsAssigned: number;
};

type GeoJsonGeometry = {
  type: string;
  coordinates: unknown;
};

function parseArgs(argv: string[]): {
  sqlitePath: string | undefined;
  jsonPath: string | undefined;
  shpPath: string | undefined;
  dryRun: boolean;
} {
  let sqlitePath = process.env.SQLITE_PATH || undefined;
  let jsonPath =
    process.env.NZ_SUBURBS_JSON_PATH ||
    "~/Downloads/nz-suburbs/newzealand_postcodes.json";
  let shpPath =
    process.env.NZ_SUBURBS_SHP_PATH ||
    "~/Downloads/nz-suburbs/nz-suburbs-and-localities.shp";
  let dryRun = false;

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--sqlite-path" && argv[i + 1]) {
      sqlitePath = argv[i + 1];
      i += 1;
    } else if (arg === "--json-path" && argv[i + 1]) {
      jsonPath = argv[i + 1];
      i += 1;
    } else if (arg === "--shp-path" && argv[i + 1]) {
      shpPath = argv[i + 1];
      i += 1;
    } else if (arg === "--dry-run") {
      dryRun = true;
    }
  }

  return { sqlitePath, jsonPath, shpPath, dryRun };
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

function normalizeName(name: string): string {
  return name.trim().toLowerCase();
}

/** Group key: same locality + first two postcode digits = one suburb. */
function localityPrefixKey(name: string, postcode: string): string {
  return `${name}\u0000${postcode.slice(0, 2)}`;
}

function thirdDigit(postcode: string): number {
  return Number(postcode[2]);
}

function isQueenstownLakesTerritory(territory: string): boolean {
  return territory.includes("Queenstown-Lakes");
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
function loadPostcodeCatalog(jsonPath: string): {
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

    const existingThird = thirdDigit(existing.postcode!);
    const candidateThird = thirdDigit(candidate.postcode!);
    if (
      candidateThird < existingThird ||
      (candidateThird === existingThird &&
        candidate.postcode! < existing.postcode!)
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

function geometryCentroid(geometry: GeoJsonGeometry | null): {
  lat: number;
  lng: number;
} | null {
  if (!geometry?.coordinates) {
    return null;
  }

  let minX = Infinity;
  let minY = Infinity;
  let maxX = -Infinity;
  let maxY = -Infinity;

  const visit = (coords: unknown): void => {
    if (!Array.isArray(coords) || coords.length === 0) {
      return;
    }
    if (typeof coords[0] === "number" && typeof coords[1] === "number") {
      const x = coords[0];
      const y = coords[1];
      minX = Math.min(minX, x);
      maxX = Math.max(maxX, x);
      minY = Math.min(minY, y);
      maxY = Math.max(maxY, y);
      return;
    }
    for (const child of coords) {
      visit(child);
    }
  };

  visit(geometry.coordinates);
  if (!Number.isFinite(minX) || !Number.isFinite(minY)) {
    return null;
  }

  return {
    lng: (minX + maxX) / 2,
    lat: (minY + maxY) / 2,
  };
}

type LinzPlace = NzSuburb;

async function loadLinzPlaces(shpPath: string): Promise<LinzPlace[]> {
  if (!existsSync(shpPath)) {
    throw new Error(
      `LINZ shapefile not found: ${shpPath}. Pass --shp-path or set NZ_SUBURBS_SHP_PATH.`,
    );
  }

  const dbfPath = shpPath.replace(/\.shp$/i, ".dbf");
  if (!existsSync(dbfPath)) {
    throw new Error(`LINZ DBF not found next to shapefile: ${dbfPath}`);
  }

  const source = await openShapefile(shpPath, dbfPath, { encoding: "utf-8" });
  const places: LinzPlace[] = [];

  while (true) {
    const result = await source.read();
    if (result.done) {
      break;
    }

    const feature = result.value;
    const properties = (feature.properties ?? {}) as Record<string, unknown>;
    const type = String(properties.type ?? "").trim();
    if (!LINZ_PLACE_TYPES.has(type)) {
      continue;
    }

    const name = String(properties.name_ascii ?? properties.name ?? "").trim();
    if (!name) {
      continue;
    }

    const territory = String(
      properties.territor_1 ?? properties.territoria ?? "",
    ).trim();
    const centroid = geometryCentroid(
      feature.geometry as GeoJsonGeometry | null,
    );
    if (!centroid || !Number.isFinite(centroid.lat) || !Number.isFinite(centroid.lng)) {
      continue;
    }

    places.push({
      name,
      postcode: null,
      state: "",
      lat: centroid.lat,
      lng: centroid.lng,
      statistic_area: territory,
    });
  }

  return places;
}

function indexByName(catalog: Map<string, NzSuburb>): Map<string, NzSuburb[]> {
  const byName = new Map<string, NzSuburb[]>();
  for (const entry of catalog.values()) {
    const key = normalizeName(entry.name);
    const list = byName.get(key);
    if (list) {
      list.push(entry);
    } else {
      byName.set(key, [entry]);
    }
  }
  return byName;
}

function distanceKm(
  a: { lat: number; lng: number },
  b: { lat: number; lng: number },
): number {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const earthRadiusKm = 6371;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * earthRadiusKm * Math.asin(Math.min(1, Math.sqrt(h)));
}

function enrichFromLinz(existing: NzSuburb, linz: LinzPlace): void {
  if (!existing.state && linz.state) {
    existing.state = linz.state;
  }
  if (!Number.isFinite(existing.lat) && Number.isFinite(linz.lat)) {
    existing.lat = linz.lat;
  }
  if (!Number.isFinite(existing.lng) && Number.isFinite(linz.lng)) {
    existing.lng = linz.lng;
  }
  // Only fill missing territory — never copy a LINZ TA onto a different
  // same-named suburb (e.g. Queenstown Sunshine Bay → Wellington 5013).
  if (!existing.statistic_area && linz.statistic_area) {
    existing.statistic_area = linz.statistic_area;
  }
}

function closestNameMatch(
  linz: LinzPlace,
  candidates: NzSuburb[],
): { match: NzSuburb; distanceKm: number } | null {
  let best: NzSuburb | null = null;
  let bestDistance = Infinity;

  for (const candidate of candidates) {
    if (!Number.isFinite(candidate.lat) || !Number.isFinite(candidate.lng)) {
      continue;
    }
    const distance = distanceKm(linz, candidate);
    if (distance < bestDistance) {
      bestDistance = distance;
      best = candidate;
    }
  }

  if (!best || bestDistance > LINZ_NAME_MATCH_MAX_KM) {
    return null;
  }

  return { match: best, distanceKm: bestDistance };
}

/**
 * LINZ is the suburb/locality source of truth. Keep postcode-JSON rows and
 * attach each LINZ place to the nearest same-named postcode row (within
 * LINZ_NAME_MATCH_MAX_KM). Unmatched LINZ places are added with a null postcode.
 *
 * Same display names in different cities (Sunshine Bay, Frankton, …) must not
 * share territorial authority or region assignment.
 */
function mergeLinzIntoCatalog(
  catalog: Map<string, NzSuburb>,
  linzPlaces: LinzPlace[],
): {
  matchedExisting: number;
  added: number;
  skippedDuplicates: number;
} {
  const byName = indexByName(catalog);
  let matchedExisting = 0;
  let added = 0;
  let skippedDuplicates = 0;

  for (const linz of linzPlaces) {
    const nameKey = normalizeName(linz.name);
    const candidates = byName.get(nameKey) ?? [];
    const nearest = closestNameMatch(linz, candidates);

    if (nearest) {
      enrichFromLinz(nearest.match, linz);
      matchedExisting += 1;
      continue;
    }

    const key = suburbKey(linz.name, null);
    const existingNull = catalog.get(key);
    if (existingNull) {
      const distance = distanceKm(linz, existingNull);
      if (distance <= LINZ_NAME_MATCH_MAX_KM) {
        enrichFromLinz(existingNull, linz);
        matchedExisting += 1;
      } else {
        // Unique index is (name, postcode); can't store two null-postcode rows
        // with the same name. Keep the first and skip the distant duplicate.
        skippedDuplicates += 1;
      }
      continue;
    }

    const entry: NzSuburb = {
      name: linz.name,
      postcode: null,
      state: linz.state,
      lat: linz.lat,
      lng: linz.lng,
      statistic_area: linz.statistic_area,
    };
    catalog.set(key, entry);
    const list = byName.get(nameKey);
    if (list) {
      list.push(entry);
    } else {
      byName.set(nameKey, [entry]);
    }
    added += 1;
  }

  return { matchedExisting, added, skippedDuplicates };
}

function hasMissingFields(
  existing: DbSuburb,
  entry: NzSuburb,
  countryId: number,
  regionId: number | null,
): boolean {
  const statisticArea = entry.statistic_area || null;
  return (
    (existing.state == null && entry.state !== "") ||
    (existing.lat == null && Number.isFinite(entry.lat)) ||
    (existing.lng == null && Number.isFinite(entry.lng)) ||
    (statisticArea != null && existing.statistic_area !== statisticArea) ||
    (existing.country_id == null && countryId != null) ||
    existing.region_id !== regionId
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
    shpSuburbLocality: 0,
    shpMatchedExisting: 0,
    shpAdded: 0,
    shpSkippedDuplicates: 0,
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

  // Region + territory are derived from this import; always sync so a bad
  // previous run (e.g. Sunshine Bay 5013 → Queenstown) can be corrected.
  const updateStmt = db.prepare(
    `
    UPDATE suburb
    SET state = COALESCE(state, ?),
        lat = COALESCE(lat, ?),
        lng = COALESCE(lng, ?),
        statistic_area = COALESCE(?, statistic_area),
        country_id = COALESCE(country_id, ?),
        region_id = ?
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
      const statisticArea = entry.statistic_area || null;

      if (!existing) {
        stats.inserted += 1;
        if (regionId != null) {
          stats.regionsAssigned += 1;
        }
        run(() => {
          insertStmt.run(
            entry.name,
            entry.postcode,
            entry.state || null,
            entry.lat,
            entry.lng,
            statisticArea,
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
      if (existing.region_id !== regionId && regionId != null) {
        stats.regionsAssigned += 1;
      }
      run(() => {
        updateStmt.run(
          entry.state || null,
          entry.lat,
          entry.lng,
          statisticArea,
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
  const {
    sqlitePath: rawSqlitePath,
    jsonPath: rawJsonPath,
    shpPath: rawShpPath,
    dryRun,
  } = parseArgs(process.argv.slice(2));
  const sqlitePath = resolveSqlitePath(rawSqlitePath);
  const jsonPath = expandPath(rawJsonPath!);
  const shpPath = expandPath(rawShpPath!);

  const {
    byKey,
    skippedAlternates,
    invalidPostcodes,
  } = loadPostcodeCatalog(jsonPath);
  const jsonUnique = byKey.size;

  const linzPlaces = await loadLinzPlaces(shpPath);
  const merge = mergeLinzIntoCatalog(byKey, linzPlaces);

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
    stats.jsonUnique = jsonUnique;
    stats.jsonSkippedAlternates = skippedAlternates;
    stats.jsonInvalidPostcodes = invalidPostcodes;
    stats.shpSuburbLocality = linzPlaces.length;
    stats.shpMatchedExisting = merge.matchedExisting;
    stats.shpAdded = merge.added;
    stats.shpSkippedDuplicates = merge.skippedDuplicates;

    console.log(dryRun ? "Dry run complete" : "NZ suburb import complete");
    console.log(`  SQLite: ${sqlitePath}`);
    console.log(`  JSON: ${jsonPath}`);
    console.log(`  SHP: ${shpPath}`);
    console.log(`  JSON entries (unique): ${stats.jsonUnique}`);
    console.log(
      `  JSON alternate postcodes skipped: ${stats.jsonSkippedAlternates}`,
    );
    if (stats.jsonInvalidPostcodes > 0) {
      console.log(
        `  JSON invalid postcodes skipped: ${stats.jsonInvalidPostcodes}`,
      );
    }
    console.log(
      `  LINZ Suburb/Locality features: ${stats.shpSuburbLocality}`,
    );
    console.log(
      `  LINZ matched existing (postcode attached by name): ${stats.shpMatchedExisting}`,
    );
    console.log(
      `  LINZ added without postcode: ${stats.shpAdded}`,
    );
    if (stats.shpSkippedDuplicates > 0) {
      console.log(
        `  LINZ duplicate names skipped: ${stats.shpSkippedDuplicates}`,
      );
    }
    console.log(`  Catalog size after merge: ${byKey.size}`);
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
