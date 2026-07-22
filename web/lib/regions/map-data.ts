import type { RegionWithCounts } from "@/lib/search/queries";
import { regionPath } from "@/lib/search/slugs";

export type RegionMapItem = RegionWithCounts;

export function formatRegionMapLabel(region: RegionMapItem): string {
  const venueLabel = region.venueCount === 1 ? "venue" : "venues";
  const dealLabel = region.dealCount === 1 ? "deal" : "deals";
  return `${region.name}, ${region.venueCount} ${venueLabel}, ${region.dealCount} ${dealLabel}`;
}

export function regionMapHref(region: RegionMapItem): string {
  return regionPath(region.name);
}

export function regionSlugById(
  regions: RegionMapItem[],
): Map<number, RegionMapItem> {
  return new Map(regions.map((region) => [region.id, region]));
}

export function regionBySlug(
  regions: RegionMapItem[],
): Map<string, RegionMapItem> {
  return new Map(regions.map((region) => [region.slug, region]));
}
