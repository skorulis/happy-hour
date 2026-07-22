import { describe, expect, it } from "vitest";
import {
  parseSuburbWhereSlug,
  regionAllSuburbsPath,
  regionPath,
  regionStatisticsPath,
  resolveSuburbWhereSlug,
  resolveVenueSuburbSlug,
  suburbMapRedirectPath,
  suburbWherePath,
  suburbWhereRedirectPath,
  suburbWhereSlug,
  venueRedirectPath,
} from "./slugs";

describe("suburbWhereSlug", () => {
  it("builds a name-postcode slug", () => {
    expect(suburbWhereSlug("Abbotsbury", "2176")).toBe("abbotsbury-2176");
  });

  it("slugifies multi-word suburb names", () => {
    expect(suburbWhereSlug("Surry Hills", "2010")).toBe("surry-hills-2010");
  });

  it("omits postcode when missing", () => {
    expect(suburbWhereSlug("Somewhere", null)).toBe("somewhere");
    expect(suburbWhereSlug("Somewhere", undefined)).toBe("somewhere");
    expect(suburbWhereSlug("Somewhere", "")).toBe("somewhere");
    expect(suburbWhereSlug("Somewhere", "  ")).toBe("somewhere");
  });
});

describe("suburbWherePath", () => {
  it("prefixes with a slash", () => {
    expect(suburbWherePath("Abbotsbury", "2176")).toBe("/abbotsbury-2176");
  });
});

describe("region slugs", () => {
  it("slugifies region names", () => {
    expect(regionPath("Sydney")).toBe("/sydney");
    expect(regionPath("Sunshine Coast")).toBe("/sunshine-coast");
  });

  it("builds all-suburbs paths", () => {
    expect(regionAllSuburbsPath("Sydney")).toBe("/sydney/all-suburbs");
    expect(regionAllSuburbsPath("Sunshine Coast")).toBe(
      "/sunshine-coast/all-suburbs",
    );
  });

  it("builds statistics paths", () => {
    expect(regionStatisticsPath("Sydney")).toBe("/sydney/statistics");
    expect(regionStatisticsPath("Sunshine Coast")).toBe(
      "/sunshine-coast/statistics",
    );
  });
});
describe("parseSuburbWhereSlug", () => {
  it("splits a trailing 4-digit postcode", () => {
    expect(parseSuburbWhereSlug("abbotsbury-2176")).toEqual({
      nameSlug: "abbotsbury",
      postcode: "2176",
    });
  });

  it("keeps hyphens in the name slug", () => {
    expect(parseSuburbWhereSlug("surry-hills-2010")).toEqual({
      nameSlug: "surry-hills",
      postcode: "2010",
    });
  });

  it("treats name-only slugs as having no postcode", () => {
    expect(parseSuburbWhereSlug("somewhere")).toEqual({
      nameSlug: "somewhere",
      postcode: null,
    });
  });

  it("does not treat non-4-digit suffixes as postcodes", () => {
    expect(parseSuburbWhereSlug("area-12")).toEqual({
      nameSlug: "area-12",
      postcode: null,
    });
  });
});

describe("suburb slug aliases", () => {
  it("resolves legacy suburb where slugs", () => {
    expect(resolveSuburbWhereSlug("sydney-2000")).toBe("sydney-cbd-2000");
    expect(resolveSuburbWhereSlug("surry-hills-2010")).toBe("surry-hills-2010");
  });

  it("resolves legacy venue suburb slugs", () => {
    expect(resolveVenueSuburbSlug("sydney")).toBe("sydney-cbd");
    expect(resolveVenueSuburbSlug("surry-hills")).toBe("surry-hills");
  });

  it("builds suburb where redirect paths", () => {
    expect(suburbWhereRedirectPath("sydney-2000")).toBe("/sydney-cbd-2000");
    expect(
      suburbWhereRedirectPath("sydney-2000", { days: "5", q: "beer" }),
    ).toBe("/sydney-cbd-2000?days=5&q=beer");
    expect(suburbWhereRedirectPath("surry-hills-2010")).toBeNull();
  });

  it("builds suburb map redirect paths", () => {
    expect(suburbMapRedirectPath("sydney-2000")).toBe("/sydney-cbd-2000/map");
    expect(suburbMapRedirectPath("surry-hills-2010")).toBeNull();
  });

  it("builds venue redirect paths", () => {
    expect(venueRedirectPath("sydney", "the-local")).toBe(
      "/sydney-cbd/the-local",
    );
    expect(venueRedirectPath("sydney", "the-local", { days: "5" })).toBe(
      "/sydney-cbd/the-local?days=5",
    );
    expect(venueRedirectPath("surry-hills", "the-local")).toBeNull();
  });
});
