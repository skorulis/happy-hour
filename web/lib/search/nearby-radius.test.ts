import { describe, expect, it } from "vitest";
import {
  NEAR_ME_MAP_RADIUS_KM,
  NEAR_ME_RADIUS_KM,
  NEARBY_SUBURB_BUFFER_KM,
  VENUE_MAP_RADIUS_KM,
  nearbySuburbRadiusKm,
  regionMapRadiusKm,
} from "./nearby-radius";

describe("NEAR_ME_RADIUS_KM", () => {
  it("is the fixed near-me search radius", () => {
    expect(NEAR_ME_RADIUS_KM).toBe(30);
  });
});

describe("NEAR_ME_MAP_RADIUS_KM", () => {
  it("is the fixed nearby map viewport radius", () => {
    expect(NEAR_ME_MAP_RADIUS_KM).toBe(2);
  });
});

describe("VENUE_MAP_RADIUS_KM", () => {
  it("is the fixed venue map viewport radius", () => {
    expect(VENUE_MAP_RADIUS_KM).toBe(1);
  });
});

describe("nearbySuburbRadiusKm", () => {
  it("uses only the buffer when suburb area is missing or invalid", () => {
    expect(nearbySuburbRadiusKm(null)).toBe(NEARBY_SUBURB_BUFFER_KM);
    expect(nearbySuburbRadiusKm(undefined)).toBe(NEARBY_SUBURB_BUFFER_KM);
    expect(nearbySuburbRadiusKm(0)).toBe(NEARBY_SUBURB_BUFFER_KM);
    expect(nearbySuburbRadiusKm(-1)).toBe(NEARBY_SUBURB_BUFFER_KM);
  });

  it("adds the buffer to the radius of an equivalent circle", () => {
    const sqkm = Math.PI;
    expect(nearbySuburbRadiusKm(sqkm)).toBeCloseTo(1 + NEARBY_SUBURB_BUFFER_KM);
  });

  it("scales with suburb size", () => {
    const oneSqkm = nearbySuburbRadiusKm(1);
    const fourSqkm = nearbySuburbRadiusKm(4);

    expect(oneSqkm).toBeCloseTo(Math.sqrt(1 / Math.PI) + NEARBY_SUBURB_BUFFER_KM);
    expect(fourSqkm).toBeCloseTo(Math.sqrt(4 / Math.PI) + NEARBY_SUBURB_BUFFER_KM);
    expect(fourSqkm).toBeGreaterThan(oneSqkm);
  });

  it("uses a positive absolute override instead of the area formula", () => {
    expect(nearbySuburbRadiusKm(Math.PI, 5)).toBe(5);
    expect(nearbySuburbRadiusKm(null, 8.5)).toBe(8.5);
  });

  it("ignores null, zero, or negative overrides", () => {
    const sqkm = Math.PI;
    const formula = 1 + NEARBY_SUBURB_BUFFER_KM;

    expect(nearbySuburbRadiusKm(sqkm, null)).toBeCloseTo(formula);
    expect(nearbySuburbRadiusKm(sqkm, undefined)).toBeCloseTo(formula);
    expect(nearbySuburbRadiusKm(sqkm, 0)).toBeCloseTo(formula);
    expect(nearbySuburbRadiusKm(sqkm, -2)).toBeCloseTo(formula);
  });
});

describe("regionMapRadiusKm", () => {
  it("is zero when region area is missing or invalid", () => {
    expect(regionMapRadiusKm(null)).toBe(0);
    expect(regionMapRadiusKm(undefined)).toBe(0);
    expect(regionMapRadiusKm(0)).toBe(0);
    expect(regionMapRadiusKm(-1)).toBe(0);
  });

  it("returns the radius of the equivalent circle without a buffer", () => {
    expect(regionMapRadiusKm(Math.PI)).toBeCloseTo(1);
    expect(regionMapRadiusKm(Math.PI * 900)).toBeCloseTo(30);
  });
});
