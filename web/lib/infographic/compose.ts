import { normalizeWeekdayPercents } from "@/lib/infographic/beer-glass";
import { normalizeStartHourShares } from "@/lib/infographic/happy-hour-clock";
import type {
  InfographicComposition,
  InfographicFormat,
  InfographicSlot,
  InfographicSlotId,
  RegionInfographicFacts,
} from "@/lib/infographic/types";

const FORMAT_SLOT_ORDER: Record<InfographicFormat, InfographicSlotId[]> = {
  page: [
    "headline",
    "weekdayMix",
    "startHourMix",
    "dayHourHeat",
    "densest",
    "perCapita",
    "topProducts",
    "coverage",
  ],
  og: ["headline", "weekdayMix", "densest", "topProducts", "coverage"],
  square: [
    "headline",
    "weekdayMix",
    "startHourMix",
    "dayHourHeat",
    "densest",
    "perCapita",
    "topProducts",
    "coverage",
  ],
  story: [
    "headline",
    "weekdayMix",
    "startHourMix",
    "dayHourHeat",
    "densest",
    "perCapita",
    "topProducts",
    "coverage",
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
    case "densest":
      if (!facts.densestSuburb) {
        if (!facts.dealLeaderSuburb) return null;
        return { id: "dealLeader", suburb: facts.dealLeaderSuburb };
      }
      return { id: "densest", suburb: facts.densestSuburb };
    case "perCapita":
      if (!facts.perCapitaSuburb) return null;
      return { id: "perCapita", suburb: facts.perCapitaSuburb };
    case "weekdayMix": {
      const total = facts.dayCounts.reduce((sum, row) => sum + row.count, 0);
      if (total <= 0 || !facts.busiestDay) return null;
      return {
        id: "weekdayMix",
        days: normalizeWeekdayPercents(facts.dayCounts),
        peakDayOfWeek: facts.busiestDay.dayOfWeek,
      };
    }
    case "startHourMix": {
      if (!facts.peakStartHour) return null;
      const hours = normalizeStartHourShares(facts.startHourCounts);
      const total = hours.reduce((sum, row) => sum + row.count, 0);
      if (total <= 0) return null;
      return {
        id: "startHourMix",
        hours,
        peakHour: facts.peakStartHour.hour,
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
    case "coverage":
      if (facts.coveragePercent === null || facts.venueCount === 0) return null;
      return {
        id: "coverage",
        percent: facts.coveragePercent,
        venuesWithDeals: facts.venuesWithDeals,
        venueCount: facts.venueCount,
      };
    case "dealLeader":
      if (!facts.dealLeaderSuburb) return null;
      return { id: "dealLeader", suburb: facts.dealLeaderSuburb };
  }
}

export function composeRegionInfographic(
  facts: RegionInfographicFacts,
  format: InfographicFormat,
): InfographicComposition {
  const slots: InfographicSlot[] = [];
  const seen = new Set<string>();

  for (const id of FORMAT_SLOT_ORDER[format]) {
    const slot = slotFromFacts(id, facts);
    if (!slot) continue;
    const key = `${slot.id}:${"suburb" in slot ? slot.suburb.name : ""}`;
    if (seen.has(key)) continue;
    seen.add(key);
    slots.push(slot);
  }

  return {
    format,
    regionName: facts.regionName,
    slots,
  };
}
