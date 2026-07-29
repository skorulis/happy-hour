import { describe, expect, it } from "vitest";
import { buildRegionInfographicFacts } from "@/lib/infographic/build-facts";
import { composeRegionInfographic } from "@/lib/infographic/compose";
import { slotHeadline, slotSupporting } from "@/lib/infographic/copy";
import type { SuburbStatistics } from "@/lib/search/queries";

function suburb(
  overrides: Partial<SuburbStatistics> & Pick<SuburbStatistics, "id" | "name">,
): SuburbStatistics {
  return {
    postcode: null,
    heroImage: null,
    dealCount: 0,
    venueCount: 0,
    sqkm: null,
    population: null,
    venuesPerSqkm: null,
    dealsPerSqkm: null,
    venuesPerThousand: null,
    dealsPerThousand: null,
    ...overrides,
  };
}

describe("buildRegionInfographicFacts", () => {
  it("aggregates totals and picks density / per-capita winners", () => {
    const facts = buildRegionInfographicFacts({
      regionId: 1,
      regionName: "Sydney",
      venuesWithDeals: 8,
      dayCounts: [
        { dayOfWeek: 6, count: 40 },
        { dayOfWeek: 5, count: 22 },
      ],
      dayHourCounts: [
        { dayOfWeek: 6, hour: 17, count: 12 },
        { dayOfWeek: 5, hour: 17, count: 8 },
      ],
      topProducts: [
        { name: "Beer", count: 12 },
        { name: "Cocktails", count: 9 },
      ],
      topFood: [
        { name: "Burger", count: 8 },
        { name: "Pizza", count: 4 },
      ],
      suburbs: [
        suburb({
          id: 1,
          name: "Surry Hills",
          dealCount: 20,
          venueCount: 10,
          sqkm: 1,
          population: 10000,
          dealsPerSqkm: 20,
          venuesPerSqkm: 10,
          dealsPerThousand: 2,
          venuesPerThousand: 1,
        }),
        suburb({
          id: 2,
          name: "Parramatta",
          dealCount: 30,
          venueCount: 15,
          sqkm: 10,
          population: 5000,
          dealsPerSqkm: 3,
          venuesPerSqkm: 1.5,
          dealsPerThousand: 6,
          venuesPerThousand: 3,
        }),
      ],
    });

    expect(facts.dealCount).toBe(50);
    expect(facts.venueCount).toBe(25);
    expect(facts.suburbCount).toBe(2);
    expect(facts.suburbsWithVenues).toBe(2);
    expect(facts.suburbsWithDeals).toBe(2);
    expect(facts.densestSuburb?.name).toBe("Surry Hills");
    expect(facts.perCapitaSuburb?.name).toBe("Parramatta");
    expect(facts.dealLeaderSuburb?.name).toBe("Parramatta");
    expect(facts.topDensityMetric).toBe("density");
    expect(facts.topDensitySuburbs).toHaveLength(2);
    expect(facts.topDensitySuburbs.map((s) => s.name)).toEqual([
      "Surry Hills",
      "Parramatta",
    ]);
    expect(facts.topDensitySuburbs[0]?.value).toBe(20);
    expect(facts.busiestDay).toEqual({ dayOfWeek: 6, count: 40 });
    expect(facts.dayCounts).toHaveLength(2);
    expect(facts.peakDayHour).toEqual({ dayOfWeek: 6, hour: 17, count: 12 });
    expect(facts.dayHourCounts).toHaveLength(2);
    expect(facts.coveragePercent).toBeCloseTo(32);
    expect(facts.topProducts).toHaveLength(2);
    expect(facts.topProducts[0]).toMatchObject({
      name: "Beer",
      count: 12,
      percent: 57,
    });
    expect(facts.topProducts[1]).toMatchObject({
      name: "Cocktails",
      count: 9,
      percent: 43,
    });
    expect(facts.topProducts.reduce((sum, hit) => sum + hit.percent, 0)).toBe(
      100,
    );
    expect(facts.topFood).toHaveLength(2);
    expect(facts.topFood[0]).toMatchObject({
      name: "Burger",
      count: 8,
      percent: 67,
    });
    expect(facts.topFood[1]).toMatchObject({
      name: "Pizza",
      count: 4,
      percent: 33,
    });
  });

  it("caps drink hits at five with percents of all drink mentions", () => {
    const facts = buildRegionInfographicFacts({
      regionId: 1,
      regionName: "Sydney",
      venuesWithDeals: 2,
      dayCounts: [],
      dayHourCounts: [],
      topProducts: [
        { name: "Beer", count: 50 },
        { name: "Wine", count: 20 },
        { name: "Cocktails", count: 15 },
        { name: "Whiskey", count: 8 },
        { name: "Prosecco", count: 4 },
        { name: "Sake", count: 3 },
      ],
      topFood: [
        { name: "Burger", count: 30 },
        { name: "Pizza", count: 20 },
        { name: "Wings", count: 15 },
        { name: "Nachos", count: 10 },
        { name: "Taco", count: 8 },
        { name: "Pasta", count: 5 },
      ],
      suburbs: [
        suburb({ id: 1, name: "Bondi", dealCount: 4, venueCount: 2 }),
      ],
    });

    expect(facts.topProducts).toHaveLength(5);
    expect(facts.topProducts.map((hit) => hit.name)).not.toContain("Sake");
    expect(facts.topProducts[0]!.percent).toBe(50);
    expect(facts.topFood).toHaveLength(5);
    expect(facts.topFood.map((hit) => hit.name)).not.toContain("Pasta");
    expect(facts.topFood[0]!.percent).toBe(34);
  });

  it("omits density and per-capita when geo data is missing", () => {
    const facts = buildRegionInfographicFacts({
      regionId: 1,
      regionName: "Sydney",
      venuesWithDeals: 2,
      dayCounts: [],
      dayHourCounts: [],
      topProducts: [],
      topFood: [],
      suburbs: [
        suburb({
          id: 1,
          name: "Nowhere",
          dealCount: 4,
          venueCount: 2,
        }),
      ],
    });

    expect(facts.densestSuburb).toBeNull();
    expect(facts.perCapitaSuburb).toBeNull();
    expect(facts.dealLeaderSuburb?.name).toBe("Nowhere");
    expect(facts.topDensityMetric).toBe("deals");
    expect(facts.topDensitySuburbs).toHaveLength(1);
    expect(facts.topDensitySuburbs[0]).toMatchObject({
      name: "Nowhere",
      value: 4,
      dealCount: 4,
    });
    expect(facts.busiestDay).toBeNull();
    expect(facts.dayCounts).toEqual([]);
    expect(facts.peakDayHour).toBeNull();
    expect(facts.coveragePercent).toBe(100);
    expect(facts.suburbCount).toBe(1);
    expect(facts.suburbsWithVenues).toBe(1);
    expect(facts.suburbsWithDeals).toBe(1);
  });

  it("counts suburbs with and without venues or deals", () => {
    const facts = buildRegionInfographicFacts({
      regionId: 1,
      regionName: "Sydney",
      venuesWithDeals: 3,
      dayCounts: [],
      dayHourCounts: [],
      topProducts: [],
      topFood: [],
      suburbs: [
        suburb({ id: 1, name: "Bondi", dealCount: 4, venueCount: 2 }),
        suburb({ id: 2, name: "Empty", dealCount: 0, venueCount: 0 }),
        suburb({ id: 3, name: "Venues only", dealCount: 0, venueCount: 5 }),
      ],
    });

    expect(facts.suburbCount).toBe(3);
    expect(facts.suburbsWithVenues).toBe(2);
    expect(facts.suburbsWithDeals).toBe(1);
    expect(facts.dealCount).toBe(4);
    expect(facts.venueCount).toBe(7);
  });
});

describe("composeRegionInfographic", () => {
  it("falls back topDensity to deal count when area is missing", () => {
    const facts = buildRegionInfographicFacts({
      regionId: 1,
      regionName: "Sydney",
      venuesWithDeals: 2,
      dayCounts: [{ dayOfWeek: 6, count: 10 }],
      dayHourCounts: [{ dayOfWeek: 6, hour: 17, count: 5 }],
      topProducts: [{ name: "Beer", count: 3 }],
      topFood: [{ name: "Burger", count: 2 }],
      suburbs: [
        suburb({
          id: 1,
          name: "Bondi",
          dealCount: 12,
          venueCount: 5,
        }),
      ],
    });

    const composition = composeRegionInfographic(facts, "page");
    const ids = composition.slots.map((slot) => slot.id);

    expect(ids).toContain("headline");
    expect(ids).toContain("coverageTriad");
    expect(ids).toContain("topDensity");
    expect(ids).not.toContain("densest");
    expect(ids).not.toContain("dealLeader");
    expect(ids).toContain("weekdayMix");
    expect(ids).toContain("dayHourHeat");
    expect(ids).toContain("topProducts");
    expect(ids).toContain("topFood");
    expect(ids).not.toContain("coverage");
    expect(ids).not.toContain("perCapita");

    const density = composition.slots.find((slot) => slot.id === "topDensity");
    expect(density?.id === "topDensity" && density.metric).toBe("deals");
    expect(density?.id === "topDensity" && density.suburbs[0]?.name).toBe(
      "Bondi",
    );
    expect(density?.id === "topDensity" && slotHeadline(density)).toBe(
      "Bondi leads",
    );
    expect(density?.id === "topDensity" && slotSupporting(density)).toBe(
      "Top 5 by deal count",
    );

    const triad = composition.slots.find((slot) => slot.id === "coverageTriad");
    expect(triad?.id === "coverageTriad" && triad.rings).toHaveLength(3);
    expect(
      triad?.id === "coverageTriad" &&
        triad.rings.find((ring) => ring.id === "venuesWithDeals")?.percent,
    ).toBe(40);
    expect(triad?.id === "coverageTriad" && slotHeadline(triad)).toBe(
      "40% venue coverage",
    );

    const mix = composition.slots.find((slot) => slot.id === "weekdayMix");
    expect(mix?.id === "weekdayMix" && mix.peakDayOfWeek).toBe(6);
    expect(mix?.id === "weekdayMix" && mix.days).toHaveLength(7);

    const heat = composition.slots.find((slot) => slot.id === "dayHourHeat");
    expect(heat?.id === "dayHourHeat" && slotHeadline(heat)).toBe(
      "Friday 5pm peaks",
    );
    expect(heat?.id === "dayHourHeat" && slotSupporting(heat)).toBe(
      "100% of happy hour coverage",
    );

    const drinks = composition.slots.find((slot) => slot.id === "topProducts");
    expect(drinks?.id === "topProducts" && slotHeadline(drinks)).toBe(
      "Beer leads",
    );
    expect(drinks?.id === "topProducts" && slotSupporting(drinks)).toBe(
      "100% of drink mentions",
    );

    const food = composition.slots.find((slot) => slot.id === "topFood");
    expect(food?.id === "topFood" && slotHeadline(food)).toBe("Burger leads");
    expect(food?.id === "topFood" && slotSupporting(food)).toBe(
      "100% of food mentions",
    );
  });

  it("uses a tighter slot set for og format", () => {
    const facts = buildRegionInfographicFacts({
      regionId: 1,
      regionName: "Sydney",
      venuesWithDeals: 8,
      dayCounts: [{ dayOfWeek: 5, count: 18 }],
      dayHourCounts: [{ dayOfWeek: 5, hour: 17, count: 4 }],
      topProducts: [{ name: "Wine", count: 4 }],
      topFood: [{ name: "Pizza", count: 3 }],
      suburbs: [
        suburb({
          id: 1,
          name: "Newtown",
          dealCount: 20,
          venueCount: 10,
          sqkm: 2,
          population: 10000,
          dealsPerSqkm: 10,
          venuesPerSqkm: 5,
          dealsPerThousand: 2,
          venuesPerThousand: 1,
        }),
      ],
    });

    const og = composeRegionInfographic(facts, "og");
    expect(og.slots.map((slot) => slot.id)).toEqual([
      "headline",
      "coverageTriad",
      "weekdayMix",
      "topProducts",
      "topDensity",
    ]);
    expect(og.slots.map((slot) => slot.id)).not.toContain("topFood");
    const density = og.slots.find((slot) => slot.id === "topDensity");
    expect(density?.id === "topDensity" && density.metric).toBe("density");
    expect(density?.id === "topDensity" && slotHeadline(density)).toBe(
      "Newtown leads",
    );
    expect(density?.id === "topDensity" && slotSupporting(density)).toBe(
      "Top 5 by deals per km²",
    );
  });

  it("caps topDensity at five suburbs ordered by deals per km²", () => {
    const facts = buildRegionInfographicFacts({
      regionId: 1,
      regionName: "Sydney",
      venuesWithDeals: 10,
      dayCounts: [],
      dayHourCounts: [],
      topProducts: [],
      topFood: [],
      suburbs: [
        suburb({
          id: 1,
          name: "A",
          dealCount: 10,
          venueCount: 2,
          sqkm: 1,
          dealsPerSqkm: 10,
        }),
        suburb({
          id: 2,
          name: "B",
          dealCount: 9,
          venueCount: 2,
          sqkm: 1,
          dealsPerSqkm: 9,
        }),
        suburb({
          id: 3,
          name: "C",
          dealCount: 8,
          venueCount: 2,
          sqkm: 1,
          dealsPerSqkm: 8,
        }),
        suburb({
          id: 4,
          name: "D",
          dealCount: 7,
          venueCount: 2,
          sqkm: 1,
          dealsPerSqkm: 7,
        }),
        suburb({
          id: 5,
          name: "E",
          dealCount: 6,
          venueCount: 2,
          sqkm: 1,
          dealsPerSqkm: 6,
        }),
        suburb({
          id: 6,
          name: "F",
          dealCount: 5,
          venueCount: 2,
          sqkm: 1,
          dealsPerSqkm: 5,
        }),
        suburb({
          id: 7,
          name: "NoArea",
          dealCount: 100,
          venueCount: 2,
        }),
      ],
    });

    expect(facts.topDensitySuburbs.map((s) => s.name)).toEqual([
      "A",
      "B",
      "C",
      "D",
      "E",
    ]);
    expect(facts.topDensityMetric).toBe("density");

    const composition = composeRegionInfographic(facts, "page");
    const density = composition.slots.find((slot) => slot.id === "topDensity");
    expect(density?.id === "topDensity" && density.suburbs).toHaveLength(5);
    expect(composition.slots.map((slot) => slot.id)).not.toContain("perCapita");
  });

  it("omits weekdayMix and dayHourHeat when there are no schedule counts", () => {
    const facts = buildRegionInfographicFacts({
      regionId: 1,
      regionName: "Sydney",
      venuesWithDeals: 1,
      dayCounts: [],
      dayHourCounts: [],
      topProducts: [],
      topFood: [],
      suburbs: [
        suburb({ id: 1, name: "Empty", dealCount: 1, venueCount: 1 }),
      ],
    });
    const composition = composeRegionInfographic(facts, "page");
    expect(composition.slots.map((slot) => slot.id)).toContain("coverageTriad");
    expect(composition.slots.map((slot) => slot.id)).toContain("topDensity");
    expect(composition.slots.map((slot) => slot.id)).not.toContain(
      "weekdayMix",
    );
    expect(composition.slots.map((slot) => slot.id)).not.toContain(
      "dayHourHeat",
    );
  });

  it("composes suburb posters with a single coverage ring and no topDensity", () => {
    const facts = buildRegionInfographicFacts({
      scope: "suburb",
      regionId: 42,
      regionName: "Surry Hills",
      suburbPostcode: "2010",
      venuesWithDeals: 8,
      dayCounts: [{ dayOfWeek: 5, count: 12 }],
      dayHourCounts: [{ dayOfWeek: 5, hour: 17, count: 6 }],
      topProducts: [{ name: "Beer", count: 4 }],
      topFood: [{ name: "Burger", count: 2 }],
      suburbs: [
        suburb({
          id: 42,
          name: "Surry Hills",
          postcode: "2010",
          dealCount: 20,
          venueCount: 10,
          sqkm: 1,
          dealsPerSqkm: 20,
        }),
      ],
    });

    expect(facts.scope).toBe("suburb");
    expect(facts.suburbPostcode).toBe("2010");

    const composition = composeRegionInfographic(facts, "page");
    expect(composition.listBasePath).toBe("/surry-hills-2010");
    const ids = composition.slots.map((slot) => slot.id);
    expect(ids).toEqual([
      "headline",
      "coverageTriad",
      "weekdayMix",
      "dayHourHeat",
      "topProducts",
      "topFood",
    ]);
    expect(ids).not.toContain("topDensity");

    const coverage = composition.slots.find(
      (slot) => slot.id === "coverageTriad",
    );
    expect(coverage?.id === "coverageTriad" && coverage.rings).toHaveLength(1);
    expect(
      coverage?.id === "coverageTriad" && coverage.rings[0]?.id,
    ).toBe("venuesWithDeals");
  });
});
