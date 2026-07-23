import regionsJson from "./regions.json";

export type RegionStatus = "live" | "in-progress" | "future" | string;

export type RegionCatalogEntry = {
  name: string;
  status: RegionStatus;
};

export const regions: RegionCatalogEntry[] = regionsJson as RegionCatalogEntry[];

const statusByName = new Map(
  regions.map((region) => [region.name.toLowerCase(), region.status]),
);

/** True when the region catalog marks this name as ready for a full suburb catalog. */
export function isRegionLive(name: string): boolean {
  return statusByName.get(name.toLowerCase()) === "live";
}
