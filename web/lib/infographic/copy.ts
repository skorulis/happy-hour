import { DAY_ABBREVIATIONS, DAY_LABELS } from "@/lib/search/schedule";
import type {
  InfographicSlot,
  RegionInfographicFacts,
  RegionProductHit,
  RegionSuburbWinner,
} from "@/lib/infographic/types";

export function formatHourLabel(hour: number): string {
  const h = ((Math.floor(hour) % 24) + 24) % 24;
  const suffix = h >= 12 ? "pm" : "am";
  const h12 = h % 12 || 12;
  return `${h12}${suffix}`;
}

export function formatRegionInfographicTitle(regionName: string): string {
  return `${regionName} happy hours by the numbers`;
}

export function formatRegionInfographicDescription(
  facts: Pick<RegionInfographicFacts, "dealCount" | "venueCount" | "regionName">,
): string {
  return `${facts.dealCount} deals across ${facts.venueCount} venues in ${facts.regionName} — densest suburbs, busiest days, and what's on offer.`;
}

export function formatDealCount(count: number): string {
  return count.toLocaleString("en-AU");
}

export function formatPerSqkmValue(value: number): string {
  return `${value.toFixed(1)} deals/km²`;
}

export function formatPerThousandValue(value: number): string {
  return `${value.toFixed(1)} deals per 1,000 people`;
}

export function formatCoveragePercent(percent: number): string {
  return `${Math.round(percent)}%`;
}

export function formatDayLabel(dayOfWeek: number): string {
  return DAY_LABELS[dayOfWeek] ?? `Day ${dayOfWeek}`;
}

export function formatDayAbbrev(dayOfWeek: number): string {
  return DAY_ABBREVIATIONS[dayOfWeek] ?? `D${dayOfWeek}`;
}

export function formatSuburbLabel(suburb: RegionSuburbWinner): string {
  return suburb.postcode ? `${suburb.name} (${suburb.postcode})` : suburb.name;
}

export function formatTopProductsLine(products: RegionProductHit[]): string {
  if (products.length === 0) {
    return "No product matches yet";
  }
  return products.map((product) => product.name).join(" · ");
}

export function formatDayHourPeakLabel(
  dayOfWeek: number,
  hour: number,
): string {
  return `${formatDayLabel(dayOfWeek)} ${formatHourLabel(hour)}`;
}

export function slotEyebrow(slot: InfographicSlot): string {
  switch (slot.id) {
    case "headline":
      return "";
    case "coverageTriad":
      return "Coverage";
    case "densest":
      return "Densest for deals";
    case "perCapita":
      return "Most deals per capita";
    case "weekdayMix":
      return "Deals by day";
    case "dayHourHeat":
      return "Happy hour heat";
    case "topProducts":
      return "What's pouring";
    case "topFood":
      return "What's cooking";
    case "dealLeader":
      return "Most deals";
  }
}

export function slotHeadline(slot: InfographicSlot): string {
  switch (slot.id) {
    case "headline":
      return `${formatDealCount(slot.dealCount)} specials across ${formatDealCount(slot.venueCount)} venues`;
    case "coverageTriad": {
      const venueRing = slot.rings.find((ring) => ring.id === "venuesWithDeals");
      return venueRing
        ? `${formatCoveragePercent(venueRing.percent)} venue coverage`
        : "Region coverage";
    }
    case "densest":
      return formatSuburbLabel(slot.suburb);
    case "perCapita":
      return formatSuburbLabel(slot.suburb);
    case "weekdayMix":
      return `${formatDayLabel(slot.peakDayOfWeek)} leads`;
    case "dayHourHeat":
      return `${formatDayHourPeakLabel(slot.peakDayOfWeek, slot.peakHour)} peaks`;
    case "topProducts": {
      const leader = slot.products[0];
      return leader ? `${leader.name} leads` : "No drink matches yet";
    }
    case "topFood": {
      const leader = slot.products[0];
      return leader ? `${leader.name} leads` : "No food matches yet";
    }
    case "dealLeader":
      return formatSuburbLabel(slot.suburb);
  }
}

export function slotSupporting(slot: InfographicSlot): string | null {
  switch (slot.id) {
    case "headline":
      return null;
    case "coverageTriad":
      return null;
    case "densest":
      return formatPerSqkmValue(slot.suburb.value);
    case "perCapita":
      return formatPerThousandValue(slot.suburb.value);
    case "weekdayMix": {
      const peak = slot.days.find((day) => day.dayOfWeek === slot.peakDayOfWeek);
      return peak ? `${peak.percent}% of scheduled deals` : null;
    }
    case "dayHourHeat": {
      if (slot.total <= 0) return null;
      const percent = Math.round((slot.peakCount / slot.total) * 100);
      return `${percent}% of happy hour coverage`;
    }
    case "topProducts": {
      const leader = slot.products[0];
      return leader ? `${leader.percent}% of drink mentions` : null;
    }
    case "topFood": {
      const leader = slot.products[0];
      return leader ? `${leader.percent}% of food mentions` : null;
    }
    case "dealLeader":
      return `${formatDealCount(slot.suburb.dealCount)} deals`;
  }
}
