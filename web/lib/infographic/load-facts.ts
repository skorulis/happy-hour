import { buildRegionInfographicFacts } from "@/lib/infographic/build-facts";
import { tallyHappyHourDayHourCounts } from "@/lib/infographic/day-hour-heat";
import { tallyProductHitsFromDeals } from "@/lib/infographic/product-tally";
import type { RegionInfographicFacts } from "@/lib/infographic/types";
import {
  countRegionVenuesWithDeals,
  listRegionDealDayCounts,
  listRegionDealSchedulesForMatching,
  listRegionDealStartHourCounts,
  listRegionDealTextsForMatching,
  listSuburbStatistics,
} from "@/lib/search/queries";

export async function loadRegionInfographicFacts(input: {
  regionId: number;
  regionName: string;
}): Promise<{
  facts: RegionInfographicFacts;
  suburbs: Awaited<ReturnType<typeof listSuburbStatistics>>;
}> {
  const [
    suburbs,
    venuesWithDeals,
    dayCounts,
    startHourCounts,
    dealSchedules,
    dealTexts,
  ] = await Promise.all([
    listSuburbStatistics({ regionId: input.regionId }),
    countRegionVenuesWithDeals(input.regionId),
    listRegionDealDayCounts(input.regionId),
    listRegionDealStartHourCounts(input.regionId),
    listRegionDealSchedulesForMatching(input.regionId),
    listRegionDealTextsForMatching(input.regionId),
  ]);

  const facts = buildRegionInfographicFacts({
    regionId: input.regionId,
    regionName: input.regionName,
    suburbs,
    venuesWithDeals,
    dayCounts,
    startHourCounts,
    dayHourCounts: tallyHappyHourDayHourCounts(dealSchedules),
    topProducts: tallyProductHitsFromDeals(dealTexts),
  });

  return { facts, suburbs };
}
