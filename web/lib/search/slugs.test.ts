import { describe, expect, it } from "vitest";
import {
  parseSuburbWhereSlug,
  suburbWherePath,
  suburbWhereSlug,
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
