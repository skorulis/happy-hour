import { describe, expect, it } from "vitest";
import {
  NEARBY_SUBURB_BUFFER_KM,
  nearbySuburbRadiusKm,
} from "./nearby-radius";

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
});
