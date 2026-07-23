import type { VenueListResult } from "@/lib/search/queries";

/**
 * Suburb venues that have no deal among the matching search results.
 * Mirrors the SQL complement used by listSuburbVenuesWithoutMatchingDeals.
 */
export function selectVenuesWithoutApplicableDeals(
  suburbVenues: VenueListResult[],
  matchingDealVenueIds: Iterable<number>,
): VenueListResult[] {
  const matchingIds = new Set(matchingDealVenueIds);
  return suburbVenues.filter((venue) => !matchingIds.has(venue.id));
}
