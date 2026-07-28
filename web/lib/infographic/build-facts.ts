import type { SuburbStatistics } from "@/lib/search/queries";
import { sortSuburbStatistics } from "@/lib/search/suburb-statistics";
import { rankTopDrinkHits } from "@/lib/infographic/drink-bars";
import { pickPeakDayHour } from "@/lib/infographic/day-hour-heat";
import type { RegionProductCount } from "@/lib/infographic/product-tally";
import type {
  RegionDayCount,
  RegionDayHourCount,
  RegionInfographicFacts,
  RegionSuburbWinner,
} from "@/lib/infographic/types";

export type RegionInfographicInputs = {
  regionId: number;
  regionName: string;
  suburbs: SuburbStatistics[];
  venuesWithDeals: number;
  dayCounts: RegionDayCount[];
  dayHourCounts: RegionDayHourCount[];
  topProducts: RegionProductCount[];
};

function toWinner(
  suburb: SuburbStatistics,
  value: number | null,
): RegionSuburbWinner | null {
  if (value === null) {
    return null;
  }
  return {
    name: suburb.name,
    postcode: suburb.postcode,
    value,
    dealCount: suburb.dealCount,
  };
}

function pickBusiestDay(dayCounts: RegionDayCount[]): RegionDayCount | null {
  if (dayCounts.length === 0) {
    return null;
  }
  return [...dayCounts].sort((a, b) => {
    const countDiff = b.count - a.count;
    if (countDiff !== 0) return countDiff;
    return a.dayOfWeek - b.dayOfWeek;
  })[0]!;
}

export function buildRegionInfographicFacts(
  input: RegionInfographicInputs,
): RegionInfographicFacts {
  const dealCount = input.suburbs.reduce(
    (sum, suburb) => sum + suburb.dealCount,
    0,
  );
  const venueCount = input.suburbs.reduce(
    (sum, suburb) => sum + suburb.venueCount,
    0,
  );
  const venuesWithDeals = Math.min(input.venuesWithDeals, venueCount);

  const byDensity = sortSuburbStatistics(input.suburbs, "density");
  const byPopulation = sortSuburbStatistics(input.suburbs, "population");
  const byDealCount = [...input.suburbs].sort((a, b) => {
    const dealDiff = b.dealCount - a.dealCount;
    if (dealDiff !== 0) return dealDiff;
    return a.name.localeCompare(b.name);
  });

  const densestCandidate = byDensity[0];
  const densestSuburb =
    densestCandidate &&
    densestCandidate.dealsPerSqkm !== null &&
    densestCandidate.sqkm !== null &&
    densestCandidate.sqkm > 0
      ? toWinner(densestCandidate, densestCandidate.dealsPerSqkm)
      : null;

  const perCapitaCandidate = byPopulation[0];
  const perCapitaSuburb =
    perCapitaCandidate &&
    perCapitaCandidate.dealsPerThousand !== null &&
    perCapitaCandidate.population !== null &&
    perCapitaCandidate.population > 0
      ? toWinner(perCapitaCandidate, perCapitaCandidate.dealsPerThousand)
      : null;

  const dealLeaderCandidate = byDealCount[0];
  const dealLeaderSuburb =
    dealLeaderCandidate && dealLeaderCandidate.dealCount > 0
      ? toWinner(dealLeaderCandidate, dealLeaderCandidate.dealCount)
      : null;

  const coveragePercent =
    venueCount > 0 ? (venuesWithDeals / venueCount) * 100 : null;

  return {
    regionId: input.regionId,
    regionName: input.regionName,
    dealCount,
    venueCount,
    venuesWithDeals,
    densestSuburb,
    perCapitaSuburb,
    dealLeaderSuburb,
    busiestDay: pickBusiestDay(input.dayCounts),
    dayCounts: input.dayCounts,
    peakDayHour: pickPeakDayHour(input.dayHourCounts),
    dayHourCounts: input.dayHourCounts,
    topProducts: rankTopDrinkHits(input.topProducts),
    coveragePercent,
  };
}
