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
    expect(facts.densestSuburb?.name).toBe("Surry Hills");
    expect(facts.perCapitaSuburb?.name).toBe("Parramatta");
    expect(facts.dealLeaderSuburb?.name).toBe("Parramatta");
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
    expect(facts.busiestDay).toBeNull();
    expect(facts.dayCounts).toEqual([]);
    expect(facts.peakDayHour).toBeNull();
    expect(facts.coveragePercent).toBe(100);
  });
});

describe("composeRegionInfographic", () => {
  it("falls back densest slot to deal leader when area is missing", () => {
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
    expect(ids).toContain("dealLeader");
    expect(ids).not.toContain("densest");
    expect(ids).toContain("weekdayMix");
    expect(ids).toContain("dayHourHeat");
    expect(ids).toContain("topProducts");
    expect(ids).toContain("topFood");
    expect(ids).toContain("coverage");
    expect(ids).not.toContain("perCapita");

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
      "weekdayMix",
      "densest",
      "topProducts",
      "coverage",
    ]);
    expect(og.slots.map((slot) => slot.id)).not.toContain("topFood");
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
    expect(composition.slots.map((slot) => slot.id)).not.toContain(
      "weekdayMix",
    );
    expect(composition.slots.map((slot) => slot.id)).not.toContain(
      "dayHourHeat",
    );
  });
});
