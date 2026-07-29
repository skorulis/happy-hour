import regionsJson from "./regions.json";

export type RegionStatus = "live" | "in-progress" | "future" | string;

export type RegionCatalogEntry = {
  name: string;
  status: RegionStatus;
  /** ISO 3166-1 alpha-3 country code (e.g. AUS, NZL). */
  country: string;
};

export const regions: RegionCatalogEntry[] = regionsJson as RegionCatalogEntry[];

const statusByName = new Map(
  regions.map((region) => [region.name.toLowerCase(), region.status]),
);

/** True when the region catalog marks this name as ready for a full suburb catalog. */
export function isRegionLive(name: string): boolean {
  return statusByName.get(name.toLowerCase()) === "live";
}
