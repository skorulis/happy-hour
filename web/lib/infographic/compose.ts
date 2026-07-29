import { normalizeWeekdayPercents } from "@/lib/infographic/beer-glass";
import {
  buildCoverageTriadRings,
  buildSuburbCoverageRings,
} from "@/lib/infographic/coverage-rings";
import type {
  InfographicComposition,
  InfographicFormat,
  InfographicSlot,
  InfographicSlotId,
  RegionInfographicFacts,
} from "@/lib/infographic/types";
import { regionPath, suburbWherePath } from "@/lib/search/slugs";

const REGION_FORMAT_SLOT_ORDER: Record<InfographicFormat, InfographicSlotId[]> =
  {
    page: [
      "headline",
      "coverageTriad",
      "weekdayMix",
      "dayHourHeat",
      "topProducts",
      "topFood",
      "topDensity",
    ],
    /** OG stays tight — drinks only, no heat/food. */
    og: [
      "headline",
      "coverageTriad",
      "weekdayMix",
      "topProducts",
      "topDensity",
    ],
    square: [
      "headline",
      "coverageTriad",
      "weekdayMix",
      "dayHourHeat",
      "topProducts",
      "topFood",
      "topDensity",
    ],
    story: [
      "headline",
      "coverageTriad",
      "weekdayMix",
      "dayHourHeat",
      "topProducts",
      "topFood",
      "topDensity",
    ],
  };

/** Suburb posters omit densest-suburbs until a suburb-level replacement exists. */
const SUBURB_FORMAT_SLOT_ORDER: Record<InfographicFormat, InfographicSlotId[]> =
  {
    page: [
      "headline",
      "coverageTriad",
      "weekdayMix",
      "dayHourHeat",
      "topProducts",
      "topFood",
    ],
    og: ["headline", "coverageTriad", "weekdayMix", "topProducts"],
    square: [
      "headline",
      "coverageTriad",
      "weekdayMix",
      "dayHourHeat",
      "topProducts",
      "topFood",
    ],
    story: [
      "headline",
      "coverageTriad",
      "weekdayMix",
      "dayHourHeat",
      "topProducts",
      "topFood",
    ],
  };

function slotFromFacts(
  id: InfographicSlotId,
  facts: RegionInfographicFacts,
): InfographicSlot | null {
  switch (id) {
    case "headline":
      return {
        id: "headline",
        dealCount: facts.dealCount,
        venueCount: facts.venueCount,
      };
    case "coverageTriad": {
      const rings =
        facts.scope === "suburb"
          ? buildSuburbCoverageRings(facts)
          : buildCoverageTriadRings(facts);
      if (!rings) return null;
      return { id: "coverageTriad", rings };
    }
    case "topDensity":
      if (facts.topDensitySuburbs.length === 0) return null;
      return {
        id: "topDensity",
        suburbs: facts.topDensitySuburbs,
        metric: facts.topDensityMetric,
      };
    case "weekdayMix": {
      const total = facts.dayCounts.reduce((sum, row) => sum + row.count, 0);
      if (total <= 0 || !facts.busiestDay) return null;
      return {
        id: "weekdayMix",
        days: normalizeWeekdayPercents(facts.dayCounts),
        peakDayOfWeek: facts.busiestDay.dayOfWeek,
      };
    }
    case "dayHourHeat": {
      if (!facts.peakDayHour) return null;
      const total = facts.dayHourCounts.reduce(
        (sum, cell) => sum + cell.count,
        0,
      );
      if (total <= 0) return null;
      return {
        id: "dayHourHeat",
        cells: facts.dayHourCounts,
        peakDayOfWeek: facts.peakDayHour.dayOfWeek,
        peakHour: facts.peakDayHour.hour,
        peakCount: facts.peakDayHour.count,
        total,
      };
    }
    case "topProducts":
      if (facts.topProducts.length === 0) return null;
      return { id: "topProducts", products: facts.topProducts };
    case "topFood":
      if (facts.topFood.length === 0) return null;
      return { id: "topFood", products: facts.topFood };
  }
}

export function composeRegionInfographic(
  facts: RegionInfographicFacts,
  format: InfographicFormat,
): InfographicComposition {
  const slots: InfographicSlot[] = [];
  const seen = new Set<string>();
  const order =
    facts.scope === "suburb"
      ? SUBURB_FORMAT_SLOT_ORDER[format]
      : REGION_FORMAT_SLOT_ORDER[format];

  for (const id of order) {
    const slot = slotFromFacts(id, facts);
    if (!slot) continue;
    const key = slot.id;
    if (seen.has(key)) continue;
    seen.add(key);
    slots.push(slot);
  }

  return {
    format,
    regionName: facts.regionName,
    listBasePath:
      facts.scope === "suburb"
        ? suburbWherePath(facts.regionName, facts.suburbPostcode)
        : regionPath(facts.regionName),
    slots,
  };
}
