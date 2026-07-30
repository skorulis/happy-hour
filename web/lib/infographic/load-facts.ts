import { buildRegionInfographicFacts } from "@/lib/infographic/build-facts";
import { tallyHappyHourDayHourCounts } from "@/lib/infographic/day-hour-heat";
import { tallyDrinkAndFoodHitsFromDeals } from "@/lib/infographic/product-tally";
import type { RegionInfographicFacts } from "@/lib/infographic/types";
import {
  countVenuesWithDeals,
  findNearbySuburbs,
  listDealDayCounts,
  listDealSchedulesForMatching,
  listDealTextsForMatching,
  listSuburbStatistics,
  type InfographicPlaceFilter,
  type NearbySuburb,
  type SuburbStatistics,
} from "@/lib/search/queries";

async function loadInfographicFacts(input: {
  filter: InfographicPlaceFilter;
  placeId: number;
  placeName: string;
  scope: RegionInfographicFacts["scope"];
  suburbListOptions: { regionId: number } | { suburbId: number };
  suburbPostcode?: string | null;
}): Promise<{
  facts: RegionInfographicFacts;
  suburbs: SuburbStatistics[];
}> {
  const [suburbs, venuesWithDeals, dayCounts, dealSchedules, dealTexts] =
    await Promise.all([
      listSuburbStatistics(input.suburbListOptions),
      countVenuesWithDeals(input.filter),
      listDealDayCounts(input.filter),
      listDealSchedulesForMatching(input.filter, { query: "happy hour" }),
      listDealTextsForMatching(input.filter),
    ]);

  const productHits = tallyDrinkAndFoodHitsFromDeals(dealTexts);

  const facts = buildRegionInfographicFacts({
    scope: input.scope,
    regionId: input.placeId,
    regionName: input.placeName,
    suburbPostcode: input.suburbPostcode,
    suburbs,
    venuesWithDeals,
    dayCounts,
    // Schedules are already What-filtered with the same FTS as search.
    dayHourCounts: tallyHappyHourDayHourCounts(dealSchedules),
    topProducts: productHits.drinks,
    topFood: productHits.food,
  });

  return { facts, suburbs };
}

export async function loadRegionInfographicFacts(input: {
  regionId: number;
  regionName: string;
}): Promise<{
  facts: RegionInfographicFacts;
  suburbs: SuburbStatistics[];
}> {
  return loadInfographicFacts({
    filter: { regionId: input.regionId },
    placeId: input.regionId,
    placeName: input.regionName,
    scope: "region",
    suburbListOptions: { regionId: input.regionId },
  });
}

export async function loadSuburbInfographicFacts(input: {
  suburbId: number;
  suburbName: string;
  suburbPostcode?: string | null;
  suburbLat?: number | null;
  suburbLng?: number | null;
}): Promise<{
  facts: RegionInfographicFacts;
  suburbs: SuburbStatistics[];
  nearbySuburbs: NearbySuburb[];
}> {
  const [base, nearbySuburbs] = await Promise.all([
    loadInfographicFacts({
      filter: { suburbId: input.suburbId },
      placeId: input.suburbId,
      placeName: input.suburbName,
      scope: "suburb",
      suburbListOptions: { suburbId: input.suburbId },
      suburbPostcode: input.suburbPostcode,
    }),
    input.suburbLat != null && input.suburbLng != null
      ? findNearbySuburbs(input.suburbLat, input.suburbLng, input.suburbId)
      : Promise.resolve([]),
  ]);

  return { ...base, nearbySuburbs };
}
