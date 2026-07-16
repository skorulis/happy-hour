import { describe, expect, it } from "vitest";
import {
  boundsFromCenterRadiusKm,
  boundsKey,
  boundsToApiParams,
  isValidBounds,
  parseBoundsParams,
} from "./bounds";
import { filtersToMapApiSearchParams } from "./url";

const sydneyBounds = {
  north: -33.86,
  south: -33.88,
  east: 151.22,
  west: 151.2,
};

describe("isValidBounds", () => {
  it("accepts valid bounds", () => {
    expect(isValidBounds(sydneyBounds)).toBe(true);
  });

  it("rejects when south is not less than north", () => {
    expect(
      isValidBounds({ ...sydneyBounds, south: sydneyBounds.north }),
    ).toBe(false);
  });

  it("rejects when west is not less than east", () => {
    expect(isValidBounds({ ...sydneyBounds, west: sydneyBounds.east })).toBe(
      false,
    );
  });

  it("rejects out-of-range coordinates", () => {
    expect(isValidBounds({ ...sydneyBounds, north: 91 })).toBe(false);
    expect(isValidBounds({ ...sydneyBounds, south: -91 })).toBe(false);
    expect(isValidBounds({ ...sydneyBounds, east: 181 })).toBe(false);
    expect(isValidBounds({ ...sydneyBounds, west: -181 })).toBe(false);
  });

  it("rejects non-finite values", () => {
    expect(isValidBounds({ ...sydneyBounds, north: NaN })).toBe(false);
  });
});

describe("boundsKey", () => {
  it("returns a stable string key", () => {
    expect(boundsKey(sydneyBounds)).toBe("-33.86,-33.88,151.22,151.2");
    expect(boundsKey(sydneyBounds)).toBe(boundsKey({ ...sydneyBounds }));
  });
});

describe("parseBoundsParams", () => {
  it("returns null when no bounds params are present", () => {
    expect(parseBoundsParams(new URLSearchParams())).toBe(null);
  });

  it("returns invalid when only some bounds params are present", () => {
    expect(
      parseBoundsParams(new URLSearchParams("north=-33.86&south=-33.88")),
    ).toBe("invalid");
  });

  it("parses valid bounds", () => {
    const params = new URLSearchParams({
      north: "-33.86",
      south: "-33.88",
      east: "151.22",
      west: "151.20",
    });

    expect(parseBoundsParams(params)).toEqual(sydneyBounds);
  });

  it("returns invalid for malformed bounds", () => {
    const params = new URLSearchParams({
      north: "-33.86",
      south: "-33.88",
      east: "151.20",
      west: "151.22",
    });

    expect(parseBoundsParams(params)).toBe("invalid");
  });
});

describe("boundsToApiParams", () => {
  it("serializes bounds to query params", () => {
    const params = boundsToApiParams(sydneyBounds);

    expect(params.get("north")).toBe("-33.86");
    expect(params.get("south")).toBe("-33.88");
    expect(params.get("east")).toBe("151.22");
    expect(params.get("west")).toBe("151.2");
  });
});

describe("boundsFromCenterRadiusKm", () => {
  it("returns a valid box around the center", () => {
    const bounds = boundsFromCenterRadiusKm(-33.87, 151.21, 5);

    expect(bounds).not.toBe(null);
    expect(isValidBounds(bounds!)).toBe(true);
    expect(bounds!.south).toBeLessThan(-33.87);
    expect(bounds!.north).toBeGreaterThan(-33.87);
    expect(bounds!.west).toBeLessThan(151.21);
    expect(bounds!.east).toBeGreaterThan(151.21);
  });

  it("scales with radius", () => {
    const small = boundsFromCenterRadiusKm(-33.87, 151.21, 1)!;
    const large = boundsFromCenterRadiusKm(-33.87, 151.21, 10)!;

    expect(large.north - large.south).toBeGreaterThan(small.north - small.south);
    expect(large.east - large.west).toBeGreaterThan(small.east - small.west);
  });

  it("rejects invalid inputs", () => {
    expect(boundsFromCenterRadiusKm(NaN, 151.21, 5)).toBe(null);
    expect(boundsFromCenterRadiusKm(-33.87, 151.21, 0)).toBe(null);
    expect(boundsFromCenterRadiusKm(-33.87, 151.21, -1)).toBe(null);
    expect(boundsFromCenterRadiusKm(100, 151.21, 5)).toBe(null);
  });
});

describe("filtersToMapApiSearchParams", () => {
  it("includes schedule and what filters but omits location params", () => {
    const params = filtersToMapApiSearchParams(
      {
        days: [1, 2],
        timeRange: { startMinute: 900, endMinute: 1080 },
        where: {
          kind: "suburb",
          id: 42,
          suburb: { id: 42, name: "Surry Hills", postcode: "2010" },
        },
        what: ["beer"],
      },
      ["beer"],
      sydneyBounds,
    );

    expect(params.get("days")).toBe("1,2");
    expect(params.get("startMinute")).toBe("900");
    expect(params.get("endMinute")).toBe("1080");
    expect(params.get("q")).toBe("beer");
    expect(params.get("north")).toBe("-33.86");
    expect(params.get("south")).toBe("-33.88");
    expect(params.get("east")).toBe("151.22");
    expect(params.get("west")).toBe("151.2");
    expect(params.get("suburbId")).toBe(null);
    expect(params.get("lat")).toBe(null);
    expect(params.get("lng")).toBe(null);
  });
});
