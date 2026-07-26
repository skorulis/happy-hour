/** Extra distance beyond the suburb boundary for nearby venue search. */
export const NEARBY_SUBURB_BUFFER_KM = 0.5;

/** Fixed radius (km) for near-me list search. */
export const NEAR_ME_RADIUS_KM = 30;

/** Max distance (km) for attributing a nearby search to a suburb in analytics. */
export const NEAREST_SUBURB_MAX_KM = 20;

/** Fixed radius (km) for the map viewport when entering from nearby. */
export const NEAR_ME_MAP_RADIUS_KM = 2;

/** Fixed radius (km) for the map viewport when entering from a venue page. */
export const VENUE_MAP_RADIUS_KM = 1;

/**
 * Radius (km) for nearby venue search: equivalent circle that fits the suburb
 * area, plus a fixed buffer.
 */
export function nearbySuburbRadiusKm(sqkm: number | null | undefined): number {
  const areaSqkm = sqkm !== null && sqkm !== undefined && sqkm > 0 ? sqkm : 0;
  const encompassingRadiusKm = Math.sqrt(areaSqkm / Math.PI);

  return encompassingRadiusKm + NEARBY_SUBURB_BUFFER_KM;
}

/**
 * Radius (km) for the map viewport when entering from a region. Region area is
 * stored as the circle that already covers its suburbs plus a buffer, so no
 * further buffer is added here.
 */
export function regionMapRadiusKm(sqkm: number | null | undefined): number {
  if (sqkm === null || sqkm === undefined || !(sqkm > 0)) {
    return 0;
  }

  return Math.sqrt(sqkm / Math.PI);
}
