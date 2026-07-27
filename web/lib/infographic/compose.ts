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
    "densest",
    "perCapita",
    "busiestDay",
    "topProducts",
    "coverage",
  ],
  og: ["headline", "densest", "busiestDay", "topProducts", "coverage"],
  square: [
    "headline",
    "densest",
    "perCapita",
    "busiestDay",
    "topProducts",
    "coverage",
  ],
  story: [
    "headline",
    "densest",
    "perCapita",
    "busiestDay",
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
    case "busiestDay":
      if (!facts.busiestDay) return null;
      return {
        id: "busiestDay",
        dayOfWeek: facts.busiestDay.dayOfWeek,
        count: facts.busiestDay.count,
      };
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
    // densest may fall back to dealLeader — avoid duplicate if dealLeader also requested
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
