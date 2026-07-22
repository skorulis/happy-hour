import type { SuburbStatistics } from "@/lib/search/queries";

export type SuburbStatsView = "density" | "population";

function compareByDealCountThenName(a: SuburbStatistics, b: SuburbStatistics): number {
  const dealCountDiff = b.dealCount - a.dealCount;
  if (dealCountDiff !== 0) return dealCountDiff;
  return a.name.localeCompare(b.name);
}

export function sortSuburbStatistics(
  suburbs: SuburbStatistics[],
  view: SuburbStatsView,
): SuburbStatistics[] {
  return [...suburbs].sort((a, b) => {
    if (view === "density") {
      const aHasSqkm = a.sqkm !== null && a.sqkm > 0;
      const bHasSqkm = b.sqkm !== null && b.sqkm > 0;
      if (aHasSqkm && !bHasSqkm) return -1;
      if (!aHasSqkm && bHasSqkm) return 1;
      if (aHasSqkm && bHasSqkm) {
        const dealDiff = (b.dealsPerSqkm ?? 0) - (a.dealsPerSqkm ?? 0);
        if (dealDiff !== 0) return dealDiff;
        return a.name.localeCompare(b.name);
      }
      return compareByDealCountThenName(a, b);
    }

    const aHasPopulation = a.population !== null && a.population > 0;
    const bHasPopulation = b.population !== null && b.population > 0;
    if (aHasPopulation && !bHasPopulation) return -1;
    if (!aHasPopulation && bHasPopulation) return 1;
    if (aHasPopulation && bHasPopulation) {
      const dealDiff = (b.dealsPerThousand ?? 0) - (a.dealsPerThousand ?? 0);
      if (dealDiff !== 0) return dealDiff;
      return a.name.localeCompare(b.name);
    }
    return compareByDealCountThenName(a, b);
  });
}
