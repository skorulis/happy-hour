import { DAY_LABELS } from "@/lib/search/schedule";
import type {
  InfographicSlot,
  RegionInfographicFacts,
  RegionProductHit,
  RegionSuburbWinner,
} from "@/lib/infographic/types";

export function formatRegionInfographicTitle(regionName: string): string {
  return `${regionName}'s happy hour map, in numbers`;
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

export function formatSuburbLabel(suburb: RegionSuburbWinner): string {
  return suburb.postcode ? `${suburb.name} (${suburb.postcode})` : suburb.name;
}

export function formatTopProductsLine(products: RegionProductHit[]): string {
  if (products.length === 0) {
    return "No product matches yet";
  }
  return products.map((product) => product.name).join(" · ");
}

export function slotEyebrow(slot: InfographicSlot): string {
  switch (slot.id) {
    case "headline":
      return "Mapped so far";
    case "densest":
      return "Densest for deals";
    case "perCapita":
      return "Most deals per capita";
    case "busiestDay":
      return "Busiest day";
    case "topProducts":
      return "What's pouring";
    case "coverage":
      return "Venue coverage";
    case "dealLeader":
      return "Most deals";
  }
}

export function slotHeadline(slot: InfographicSlot): string {
  switch (slot.id) {
    case "headline":
      return `${formatDealCount(slot.dealCount)} deals`;
    case "densest":
      return formatSuburbLabel(slot.suburb);
    case "perCapita":
      return formatSuburbLabel(slot.suburb);
    case "busiestDay":
      return formatDayLabel(slot.dayOfWeek);
    case "topProducts":
      return formatTopProductsLine(slot.products);
    case "coverage":
      return formatCoveragePercent(slot.percent);
    case "dealLeader":
      return formatSuburbLabel(slot.suburb);
  }
}

export function slotSupporting(slot: InfographicSlot): string | null {
  switch (slot.id) {
    case "headline":
      return `${formatDealCount(slot.venueCount)} venues`;
    case "densest":
      return formatPerSqkmValue(slot.suburb.value);
    case "perCapita":
      return formatPerThousandValue(slot.suburb.value);
    case "busiestDay":
      return `${formatDealCount(slot.count)} scheduled deals`;
    case "topProducts":
      return slot.products.length > 0
        ? "Most often named in deal text"
        : null;
    case "coverage":
      return `${formatDealCount(slot.venuesWithDeals)} of ${formatDealCount(slot.venueCount)} venues have a deal`;
    case "dealLeader":
      return `${formatDealCount(slot.suburb.dealCount)} deals`;
  }
}
