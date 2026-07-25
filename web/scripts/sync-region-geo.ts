import { eq, isNotNull } from "drizzle-orm";
import type { PostgresJsDatabase } from "drizzle-orm/postgres-js";
import * as schema from "../db/schema";
import {
  regionGeoFromSuburbCenters,
  type SuburbCenter,
} from "../lib/search/region-geo";

export type RegionGeoSyncResult = {
  framed: number;
  cleared: number;
};

/**
 * Recomputes every region's map framing from the coordinates of its suburbs.
 * Safe to re-run: regions whose suburbs have no coordinates are reset to null
 * so the map falls back to its default camera.
 */
export async function syncRegionGeo(
  db: PostgresJsDatabase<typeof schema>,
): Promise<RegionGeoSyncResult> {
  const regions = await db
    .select({ id: schema.geographicRegion.id })
    .from(schema.geographicRegion);

  const suburbs = await db
    .select({
      regionId: schema.suburb.regionId,
      lat: schema.suburb.lat,
      lng: schema.suburb.lng,
    })
    .from(schema.suburb)
    .where(isNotNull(schema.suburb.regionId));

  const centersByRegionId = new Map<number, SuburbCenter[]>();
  for (const row of suburbs) {
    if (row.regionId == null) {
      continue;
    }
    const centers = centersByRegionId.get(row.regionId);
    if (centers) {
      centers.push(row);
    } else {
      centersByRegionId.set(row.regionId, [row]);
    }
  }

  let framed = 0;
  let cleared = 0;

  for (const region of regions) {
    const geo = regionGeoFromSuburbCenters(
      centersByRegionId.get(region.id) ?? [],
    );

    await db
      .update(schema.geographicRegion)
      .set({
        lat: geo?.lat ?? null,
        lng: geo?.lng ?? null,
        sqkm: geo?.sqkm ?? null,
      })
      .where(eq(schema.geographicRegion.id, region.id));

    if (geo) {
      framed += 1;
    } else {
      cleared += 1;
    }
  }

  return { framed, cleared };
}
