/**
 * Build simplified TopoJSON region boundaries from ABS ASGS GeoJSON files.
 *
 * Local files: set ASGS_BOUNDARIES_PATH to a directory containing GCCSA/LGA/STE GeoJSON.
 *
 * Remote fetch: npm run build:region-boundaries -- --fetch
 *   Downloads region polygons from geo.abs.gov.au and state outline from GitHub.
 *
 * Usage: npm run build:region-boundaries [-- --fetch]
 */
import { loadScriptEnv } from "../load-script-env";

loadScriptEnv();

import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import simplify from "@turf/simplify";
import type {
  Feature,
  FeatureCollection,
  GeoJsonProperties,
  Geometry,
} from "geojson";
import { topology } from "topojson-server";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DATA_DIR = path.resolve(__dirname, "../data");

type AbsLayer = "GCCSA" | "LGA";

type RegionBoundaryConfig = {
  absLayer: AbsLayer;
  absName: string;
};

type RegionBoundariesFile = Record<string, RegionBoundaryConfig>;

const LAYER_FILES: Record<AbsLayer, string[]> = {
  GCCSA: [
    "GCCSA_2021_AUST_GDA2020.json",
    "GCCSA_2021_AUST_GDA94.json",
    "gccsa.geojson",
  ],
  LGA: [
    "LGA_2021_AUST_GDA2020.json",
    "LGA_2021_AUST_GDA94.json",
    "lga.geojson",
  ],
};

const OUTLINE_FILES = [
  "STE_2021_AUST_GDA2020.json",
  "STE_2021_AUST_GDA94.json",
  "ste.geojson",
];

const ABS_LAYER_ENDPOINTS: Record<AbsLayer, string> = {
  GCCSA:
    "https://geo.abs.gov.au/arcgis/rest/services/ASGS2021/GCCSA/MapServer/0/query",
  LGA: "https://geo.abs.gov.au/arcgis/rest/services/ASGS2021/LGA/MapServer/0/query",
};

const ABS_NAME_FIELDS: Record<AbsLayer, string> = {
  GCCSA: "gccsa_name_2021",
  LGA: "lga_name_2021",
};

const AUSTRALIA_STATES_URL =
  "https://raw.githubusercontent.com/tonywr71/GeoJson-Data/master/australian-states.json";

function expandPath(rawPath: string): string {
  const homedir = process.env.HOME ?? "";
  return rawPath.startsWith("~")
    ? path.join(homedir, rawPath.slice(1))
    : rawPath;
}

function resolveBoundariesDir(): string {
  const raw =
    process.env.ASGS_BOUNDARIES_PATH ??
    "~/Downloads/asgs-boundaries/2021/GeoJSON";
  return path.resolve(expandPath(raw));
}

function readJson<T>(filePath: string): T {
  return JSON.parse(readFileSync(filePath, "utf8")) as T;
}

function findLayerFile(dir: string, candidates: string[]): string {
  for (const name of candidates) {
    const full = path.join(dir, name);
    if (existsSync(full)) {
      return full;
    }
  }
  throw new Error(
    `Could not find layer file in ${dir}. Tried: ${candidates.join(", ")}`,
  );
}

function getFeatureName(properties: GeoJsonProperties): string | null {
  if (!properties) {
    return null;
  }
  const keys = [
    "GCCSA_NAME21",
    "LGA_NAME21",
    "STE_NAME21",
    "GCCSA_NAME_2021",
    "LGA_NAME_2021",
    "STE_NAME_2021",
    "gccsa_name_2021",
    "lga_name_2021",
    "ste_name_2021",
    "NAME",
    "name",
    "STATE_NAME",
  ];
  for (const key of keys) {
    const value = properties[key];
    if (typeof value === "string" && value.trim()) {
      return value.trim();
    }
  }
  return null;
}

function loadLayerCollection(
  dir: string,
  layer: AbsLayer,
): FeatureCollection {
  const filePath = findLayerFile(dir, LAYER_FILES[layer]);
  const parsed = readJson<FeatureCollection | Feature>(filePath);
  if (parsed.type === "FeatureCollection") {
    return parsed;
  }
  return { type: "FeatureCollection", features: [parsed] };
}

function findFeatureByName(
  collection: FeatureCollection,
  absName: string,
): Feature {
  const normalized = absName.trim().toLowerCase();
  const match = collection.features.find((feature) => {
    const name = getFeatureName(feature.properties);
    return name?.trim().toLowerCase() === normalized;
  });
  if (!match) {
    const available = collection.features
      .map((feature) => getFeatureName(feature.properties))
      .filter(Boolean)
      .slice(0, 10);
    throw new Error(
      `Feature "${absName}" not found. Sample names: ${available.join(", ")}`,
    );
  }
  return match;
}

function simplifyFeature(feature: Feature, tolerance = 0.01): Feature {
  return simplify(feature, {
    tolerance,
    highQuality: true,
    mutate: false,
  }) as Feature;
}

function loadOutlineCollection(dir: string): FeatureCollection {
  const filePath = findLayerFile(dir, OUTLINE_FILES);
  return readJson<FeatureCollection>(filePath);
}

async function fetchAbsFeature(
  layer: AbsLayer,
  absName: string,
): Promise<Feature> {
  const params = new URLSearchParams({
    where: `${ABS_NAME_FIELDS[layer]}='${absName.replace(/'/g, "''")}'`,
    outFields: "*",
    outSR: "4326",
    f: "geojson",
  });
  const url = `${ABS_LAYER_ENDPOINTS[layer]}?${params.toString()}`;
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`ABS fetch failed (${response.status}): ${url}`);
  }
  const collection = (await response.json()) as FeatureCollection;
  if (!collection.features?.length) {
    throw new Error(`ABS returned no features for ${layer}:${absName}`);
  }
  return collection.features[0]!;
}

async function fetchAustraliaOutline(): Promise<FeatureCollection> {
  const response = await fetch(AUSTRALIA_STATES_URL);
  if (!response.ok) {
    throw new Error(`Failed to fetch Australia outline (${response.status})`);
  }
  return (await response.json()) as FeatureCollection;
}

function writeTopojsonOutputs(
  regionFeatures: Feature[],
  outlineFeatures: Feature[],
): void {
  mkdirSync(DATA_DIR, { recursive: true });

  const regionsCollection: FeatureCollection = {
    type: "FeatureCollection",
    features: regionFeatures,
  };

  const regionsTopo = topology(
    { regions: regionsCollection as FeatureCollection<Geometry> },
    1e5,
  );
  writeFileSync(
    path.join(DATA_DIR, "regions-australia.json"),
    JSON.stringify(regionsTopo),
  );
  console.log(`Wrote ${path.join(DATA_DIR, "regions-australia.json")}`);

  const outlineTopo = topology(
    {
      australia: {
        type: "FeatureCollection",
        features: outlineFeatures,
      } as FeatureCollection<Geometry>,
    },
    1e5,
  );
  writeFileSync(
    path.join(DATA_DIR, "australia-outline.json"),
    JSON.stringify(outlineTopo),
  );
  console.log(`Wrote ${path.join(DATA_DIR, "australia-outline.json")}`);
}

async function buildFromFetch(config: RegionBoundariesFile): Promise<void> {
  const regionFeatures: Feature[] = [];

  for (const [regionSlug, entry] of Object.entries(config)) {
    const source = await fetchAbsFeature(entry.absLayer, entry.absName);
    const tolerance = entry.absLayer === "GCCSA" ? 0.02 : 0.01;
    const simplified = simplifyFeature(source, tolerance);
    simplified.properties = {
      ...simplified.properties,
      regionSlug,
      regionName: entry.absName,
    };
    regionFeatures.push(simplified);
    console.log(`✓ ${regionSlug} ← ${entry.absLayer}:${entry.absName} (fetched)`);
  }

  const outlineCollection = await fetchAustraliaOutline();
  const simplifiedStates = outlineCollection.features.map((feature) =>
    simplifyFeature(feature, 0.05),
  );

  writeTopojsonOutputs(regionFeatures, simplifiedStates);
}

function buildFromLocal(
  boundariesDir: string,
  config: RegionBoundariesFile,
): void {
  const layerCache = new Map<AbsLayer, FeatureCollection>();
  function getLayer(layer: AbsLayer): FeatureCollection {
    const cached = layerCache.get(layer);
    if (cached) {
      return cached;
    }
    const collection = loadLayerCollection(boundariesDir, layer);
    layerCache.set(layer, collection);
    return collection;
  }

  const regionFeatures: Feature[] = [];

  for (const [regionSlug, entry] of Object.entries(config)) {
    const source = findFeatureByName(getLayer(entry.absLayer), entry.absName);
    const tolerance = entry.absLayer === "GCCSA" ? 0.02 : 0.01;
    const simplified = simplifyFeature(source, tolerance);
    simplified.properties = {
      ...simplified.properties,
      regionSlug,
      regionName: entry.absName,
    };
    regionFeatures.push(simplified);
    console.log(`✓ ${regionSlug} ← ${entry.absLayer}:${entry.absName}`);
  }

  const outlineCollection = loadOutlineCollection(boundariesDir);
  const simplifiedStates = outlineCollection.features.map((feature) =>
    simplifyFeature(feature, 0.05),
  );

  writeTopojsonOutputs(regionFeatures, simplifiedStates);
}

async function main(): Promise<void> {
  const useFetch = process.argv.includes("--fetch");
  const configPath = path.join(DATA_DIR, "region-boundaries.json");
  const config = readJson<RegionBoundariesFile>(configPath);

  if (useFetch) {
    await buildFromFetch(config);
    return;
  }

  const boundariesDir = resolveBoundariesDir();
  if (!existsSync(boundariesDir)) {
    console.error(
      `ASGS boundaries directory not found: ${boundariesDir}\n` +
        "Download ABS ASGS Edition 3 GeoJSON boundaries, set ASGS_BOUNDARIES_PATH,\n" +
        "or run: npm run build:region-boundaries -- --fetch",
    );
    process.exit(1);
  }

  buildFromLocal(boundariesDir, config);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
