import { describe, expect, it } from "vitest";
import {
  buildCoverageTriadRings,
  clampCoveragePercent,
  coveragePercentOf,
  coverageRingDash,
  coverageRingEyebrow,
  coverageRingSupporting,
} from "@/lib/infographic/coverage-rings";

describe("coverage-rings", () => {
  it("clamps percent into 0–100", () => {
    expect(clampCoveragePercent(-5)).toBe(0);
    expect(clampCoveragePercent(140)).toBe(100);
    expect(clampCoveragePercent(42.6)).toBe(42.6);
    expect(clampCoveragePercent(Number.NaN)).toBe(0);
  });

  it("computes coverage percent of a ratio", () => {
    expect(coveragePercentOf(8, 25)).toBeCloseTo(32);
    expect(coveragePercentOf(2, 0)).toBe(0);
    expect(coveragePercentOf(0, 10)).toBe(0);
  });

  it("builds dasharray for a progress ring", () => {
    const full = coverageRingDash(100);
    const half = coverageRingDash(50);
    expect(full.dasharray.startsWith(`${full.circumference} `)).toBe(true);
    expect(half.dasharray.startsWith(`${half.circumference / 2} `)).toBe(true);
  });

  it("builds three triad rings from facts", () => {
    const rings = buildCoverageTriadRings({
      suburbCount: 10,
      suburbsWithVenues: 8,
      suburbsWithDeals: 5,
      venueCount: 20,
      venuesWithDeals: 10,
    });

    expect(rings).toHaveLength(3);
    expect(rings![0]).toMatchObject({
      id: "suburbsWithVenues",
      percent: 80,
      scaleCount: 8,
      scaleUnit: "suburbs",
      numerator: 8,
      denominator: 10,
    });
    expect(rings![1]).toMatchObject({
      id: "suburbsWithDeals",
      percent: 50,
      scaleCount: 5,
      scaleUnit: "suburbs",
    });
    expect(rings![2]).toMatchObject({
      id: "venuesWithDeals",
      percent: 50,
      scaleCount: 10,
      scaleUnit: "venues",
    });
    expect(coverageRingEyebrow(rings![0]!)).toBe("Suburbs with venues");
    expect(coverageRingSupporting(rings![2]!)).toBe(
      "10 of 20 venues have a deal",
    );
  });

  it("returns null when there are no suburbs", () => {
    expect(
      buildCoverageTriadRings({
        suburbCount: 0,
        suburbsWithVenues: 0,
        suburbsWithDeals: 0,
        venueCount: 0,
        venuesWithDeals: 0,
      }),
    ).toBeNull();
  });
});
