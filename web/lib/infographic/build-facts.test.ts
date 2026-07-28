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
      startHourCounts: [
        { hour: 17, count: 30 },
        { hour: 18, count: 20 },
      ],
      topProducts: [
        { name: "Beer", count: 12 },
        { name: "Cocktails", count: 9 },
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
    expect(facts.peakStartHour).toEqual({ hour: 17, count: 30 });
    expect(facts.startHourCounts).toHaveLength(2);
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
  });

  it("caps drink hits at five with percents of all drink mentions", () => {
    const facts = buildRegionInfographicFacts({
      regionId: 1,
      regionName: "Sydney",
      venuesWithDeals: 2,
      dayCounts: [],
      startHourCounts: [],
      topProducts: [
        { name: "Beer", count: 50 },
        { name: "Wine", count: 20 },
        { name: "Cocktails", count: 15 },
        { name: "Whiskey", count: 8 },
        { name: "Prosecco", count: 4 },
        { name: "Sake", count: 3 },
      ],
      suburbs: [
        suburb({ id: 1, name: "Bondi", dealCount: 4, venueCount: 2 }),
      ],
    });

    expect(facts.topProducts).toHaveLength(5);
    expect(facts.topProducts.map((hit) => hit.name)).not.toContain("Sake");
    expect(facts.topProducts[0]!.percent).toBe(50);
  });

  it("omits density and per-capita when geo data is missing", () => {
    const facts = buildRegionInfographicFacts({
      regionId: 1,
      regionName: "Sydney",
      venuesWithDeals: 2,
      dayCounts: [],
      startHourCounts: [],
      topProducts: [],
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
    expect(facts.peakStartHour).toBeNull();
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
      startHourCounts: [{ hour: 17, count: 8 }],
      topProducts: [{ name: "Beer", count: 3 }],
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
    expect(ids).toContain("startHourMix");
    expect(ids).toContain("topProducts");
    expect(ids).toContain("coverage");
    expect(ids).not.toContain("perCapita");

    const mix = composition.slots.find((slot) => slot.id === "weekdayMix");
    expect(mix?.id === "weekdayMix" && mix.peakDayOfWeek).toBe(6);
    expect(mix?.id === "weekdayMix" && mix.days).toHaveLength(7);

    const clock = composition.slots.find((slot) => slot.id === "startHourMix");
    expect(clock?.id === "startHourMix" && clock.peakHour).toBe(17);
    expect(clock?.id === "startHourMix" && slotHeadline(clock)).toBe(
      "5pm starts",
    );
    expect(clock?.id === "startHourMix" && slotSupporting(clock)).toBe(
      "100% of timed deals start then",
    );

    const drinks = composition.slots.find((slot) => slot.id === "topProducts");
    expect(drinks?.id === "topProducts" && slotHeadline(drinks)).toBe(
      "Beer leads",
    );
    expect(drinks?.id === "topProducts" && slotSupporting(drinks)).toBe(
      "100% of drink mentions",
    );
  });

  it("uses a tighter slot set for og format", () => {
    const facts = buildRegionInfographicFacts({
      regionId: 1,
      regionName: "Sydney",
      venuesWithDeals: 8,
      dayCounts: [{ dayOfWeek: 5, count: 18 }],
      startHourCounts: [{ hour: 17, count: 10 }],
      topProducts: [{ name: "Wine", count: 4 }],
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
  });

  it("omits weekdayMix and startHourMix when there are no schedule counts", () => {
    const facts = buildRegionInfographicFacts({
      regionId: 1,
      regionName: "Sydney",
      venuesWithDeals: 1,
      dayCounts: [],
      startHourCounts: [],
      topProducts: [],
      suburbs: [
        suburb({ id: 1, name: "Empty", dealCount: 1, venueCount: 1 }),
      ],
    });
    const composition = composeRegionInfographic(facts, "page");
    expect(composition.slots.map((slot) => slot.id)).not.toContain(
      "weekdayMix",
    );
    expect(composition.slots.map((slot) => slot.id)).not.toContain(
      "startHourMix",
    );
  });
});
