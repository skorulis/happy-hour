import { describe, expect, it } from "vitest";
import regionBoundaries from "@/data/region-boundaries.json";
import {
  formatRegionMapLabel,
  regionBySlug,
  regionMapHref,
} from "@/lib/regions/map-data";
import { regionSlug } from "@/lib/search/slugs";

describe("region map data helpers", () => {
  it("formats accessible region labels", () => {
    expect(
      formatRegionMapLabel({
        id: 1,
        name: "Sydney",
        slug: "sydney",
        venueCount: 1,
        dealCount: 2,
      }),
    ).toBe("Sydney, 1 venue, 2 deals");
  });

  it("builds region hrefs from slug data", () => {
    expect(
      regionMapHref({
        id: 1,
        name: "Sunshine Coast",
        slug: "sunshine-coast",
        venueCount: 0,
        dealCount: 0,
      }),
    ).toBe("/sunshine-coast");
  });

  it("indexes regions by slug", () => {
    const regions = [
      {
        id: 1,
        name: "Sydney",
        slug: "sydney",
        venueCount: 10,
        dealCount: 20,
      },
    ];
    expect(regionBySlug(regions).get("sydney")?.name).toBe("Sydney");
  });
});

describe("region boundary config", () => {
  it("uses slugs aligned with product region names", () => {
    expect(regionBoundaries).toHaveProperty(regionSlug("Sydney"));
    expect(regionBoundaries).toHaveProperty(regionSlug("Sunshine Coast"));
  });

  it("maps each slug to an ABS layer and name", () => {
    for (const entry of Object.values(regionBoundaries)) {
      expect(["GCCSA", "LGA"]).toContain(entry.absLayer);
      expect(entry.absName.trim().length).toBeGreaterThan(0);
    }
  });
});
