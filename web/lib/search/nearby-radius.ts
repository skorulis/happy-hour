/** Extra distance beyond the suburb boundary for nearby venue search. */
export const NEARBY_SUBURB_BUFFER_KM = 0.5;

/** Fixed radius (km) for near-me list search. */
export const NEAR_ME_RADIUS_KM = 30;

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
