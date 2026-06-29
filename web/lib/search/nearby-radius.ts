/** Extra distance beyond the suburb boundary for nearby venue search. */
export const NEARBY_SUBURB_BUFFER_KM = 0.5;

/**
 * Radius (km) for nearby venue search: equivalent circle that fits the suburb
 * area, plus a fixed buffer.
 */
export function nearbySuburbRadiusKm(sqkm: number | null | undefined): number {
  const areaSqkm = sqkm !== null && sqkm !== undefined && sqkm > 0 ? sqkm : 0;
  const encompassingRadiusKm = Math.sqrt(areaSqkm / Math.PI);

  return encompassingRadiusKm + NEARBY_SUBURB_BUFFER_KM;
}
