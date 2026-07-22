import { feature } from "topojson-client";
import type { Feature, FeatureCollection, Geometry } from "geojson";
import { geoMercator, geoPath, type GeoProjection } from "d3-geo";
import type { Topology } from "topojson-specification";
import australiaOutlineTopo from "@/data/australia-outline.json";
import regionsAustraliaTopo from "@/data/regions-australia.json";

const australiaOutline = australiaOutlineTopo as unknown as Topology;
const regionsAustralia = regionsAustraliaTopo as unknown as Topology;

export const MAP_WIDTH = 800;
export const MAP_HEIGHT = 600;

type RegionGeographyProperties = {
  regionSlug?: string;
  regionName?: string;
};

export type MapPathFeature = {
  slug: string | null;
  path: string;
};

function asFeatureCollection(
  topo: Topology,
  objectName: string,
): FeatureCollection {
  const object = topo.objects[objectName];
  if (!object) {
    throw new Error(`Missing TopoJSON object: ${objectName}`);
  }
  return feature(topo, object) as FeatureCollection<Geometry>;
}

export function createAustraliaProjection(
  width = MAP_WIDTH,
  height = MAP_HEIGHT,
): GeoProjection {
  const outline = asFeatureCollection(australiaOutline, "australia");
  return geoMercator()
    .fitSize([width, height], outline)
    .clipAngle(180);
}

/** Drop antimeridian clip artifacts (zero-height line segments). */
export function cleanSvgPath(pathData: string): string {
  return pathData
    .split(/(?=M)/)
    .filter(Boolean)
    .filter((part) => {
      const numbers = part.match(/-?\d+\.?\d*/g)?.map(Number) ?? [];
      const xs = numbers.filter((_, index) => index % 2 === 0);
      const ys = numbers.filter((_, index) => index % 2 === 1);
      if (xs.length < 3 || ys.length < 3) {
        return false;
      }
      const width = Math.max(...xs) - Math.min(...xs);
      const height = Math.max(...ys) - Math.min(...ys);
      return width > 1 && height > 1;
    })
    .join("");
}

export function buildOutlinePaths(projection: GeoProjection): string[] {
  const outline = asFeatureCollection(australiaOutline, "australia");
  const pathGenerator = geoPath(projection);
  return outline.features
    .map((outlineFeature) => cleanSvgPath(pathGenerator(outlineFeature) ?? ""))
    .filter((pathData) => pathData.length > 0);
}

export function buildRegionPaths(
  projection: GeoProjection,
): MapPathFeature[] {
  const regions = asFeatureCollection(regionsAustralia, "regions");
  const pathGenerator = geoPath(projection);

  return regions.features.flatMap((regionFeature) => {
    const properties =
      regionFeature.properties as RegionGeographyProperties | null;
    const slug = properties?.regionSlug ?? null;
    const pathData = cleanSvgPath(pathGenerator(regionFeature) ?? "");
    if (!pathData) {
      return [];
    }
    return [{ slug, path: pathData }];
  });
}
