import { describe, expect, it } from "vitest";
import {
  barWidthPercent,
  buildDrinkBarRows,
  drinkBarColor,
  DRINK_BAR_MAX_ICONS,
  iconCountForWidth,
  rankTopDrinkHits,
  TOP_DRINK_LIMIT,
} from "@/lib/infographic/drink-bars";
import {
  isDrinkProductName,
  isFoodProductName,
  tallyDrinkAndFoodHitsFromDeals,
  tallyProductHitsFromDeals,
} from "@/lib/infographic/product-tally";

describe("isDrinkProductName", () => {
  it("includes drinks-tree keywords", () => {
    expect(isDrinkProductName("beer")).toBe(true);
    expect(isDrinkProductName("Beer")).toBe(true);
    expect(isDrinkProductName("cocktails")).toBe(true);
    expect(isDrinkProductName("schooner")).toBe(true);
    expect(isDrinkProductName("negroni")).toBe(true);
  });

  it("excludes non-drink products", () => {
    expect(isDrinkProductName("music")).toBe(false);
    expect(isDrinkProductName("burger")).toBe(false);
    expect(isDrinkProductName("pizza")).toBe(false);
  });
});

describe("isFoodProductName", () => {
  it("includes food-tree keywords", () => {
    expect(isFoodProductName("burger")).toBe(true);
    expect(isFoodProductName("Pizza")).toBe(true);
    expect(isFoodProductName("wings")).toBe(true);
    expect(isFoodProductName("fish & chips")).toBe(true);
  });

  it("excludes non-food products", () => {
    expect(isFoodProductName("beer")).toBe(false);
    expect(isFoodProductName("music")).toBe(false);
    expect(isFoodProductName("cocktails")).toBe(false);
  });
});

describe("tallyProductHitsFromDeals", () => {
  it("returns an empty list when there are no deals", () => {
    expect(tallyProductHitsFromDeals([])).toEqual([]);
  });

  it("counts drink matches and excludes non-drinks", () => {
    const hits = tallyProductHitsFromDeals([
      { title: "$8 schooners", details: null, conditions: null },
      { title: "Beer special", details: "Pints from 4pm", conditions: null },
      { title: "Live music night", details: null, conditions: null },
      { title: "Burger deal", details: null, conditions: null },
      { title: "Cocktail deal", details: "House cocktails", conditions: null },
      { title: "Cocktail deal", details: "More cocktails", conditions: null },
    ]);

    expect(hits.length).toBeGreaterThan(0);
    expect(hits.every((hit) => isDrinkProductName(hit.name))).toBe(true);
    expect(hits.some((hit) => hit.name.toLowerCase() === "music")).toBe(false);
    expect(hits.some((hit) => hit.name.toLowerCase() === "burger")).toBe(false);
    expect(hits[0]!.count).toBeGreaterThanOrEqual(hits[1]?.count ?? 0);
  });

  it("respects the sample limit", () => {
    const deals = Array.from({ length: 5 }, () => ({
      title: "$6 beer",
      details: null,
      conditions: null,
    }));

    const limited = tallyProductHitsFromDeals(deals, 2);
    const full = tallyProductHitsFromDeals(deals);

    const limitedBeer = limited.find(
      (hit) => hit.name.toLowerCase() === "beer",
    );
    const fullBeer = full.find((hit) => hit.name.toLowerCase() === "beer");

    if (limitedBeer && fullBeer) {
      expect(limitedBeer.count).toBeLessThanOrEqual(fullBeer.count);
      expect(limitedBeer.count).toBeLessThanOrEqual(2);
    }
  });
});

describe("tallyDrinkAndFoodHitsFromDeals", () => {
  it("splits drink and food hits in one pass", () => {
    const hits = tallyDrinkAndFoodHitsFromDeals([
      { title: "$8 schooners", details: null, conditions: null },
      { title: "Burger night", details: "Cheeseburger special", conditions: null },
      { title: "Pizza and beer", details: null, conditions: null },
      { title: "Live music", details: null, conditions: null },
    ]);

    expect(hits.drinks.every((hit) => isDrinkProductName(hit.name))).toBe(true);
    expect(hits.food.every((hit) => isFoodProductName(hit.name))).toBe(true);
    expect(hits.food.some((hit) => hit.name.toLowerCase() === "burger")).toBe(
      true,
    );
    expect(hits.drinks.some((hit) => hit.name.toLowerCase() === "burger")).toBe(
      false,
    );
  });
});

describe("rankTopDrinkHits", () => {
  it("caps at top 5 and attaches percents over the full list", () => {
    const ranked = rankTopDrinkHits([
      { name: "Beer", count: 40 },
      { name: "Wine", count: 30 },
      { name: "Cocktails", count: 20 },
      { name: "Whiskey", count: 5 },
      { name: "Prosecco", count: 3 },
      { name: "Sake", count: 2 },
    ]);

    expect(ranked).toHaveLength(TOP_DRINK_LIMIT);
    expect(ranked.map((hit) => hit.name)).toEqual([
      "Beer",
      "Wine",
      "Cocktails",
      "Whiskey",
      "Prosecco",
    ]);
    expect(ranked[0]!.percent).toBe(40);
    expect(ranked.reduce((sum, hit) => sum + hit.percent, 0)).toBeLessThan(100);
    expect(ranked.every((hit) => hit.percent > 0)).toBe(true);
  });

  it("sums to 100 when five or fewer drinks fill the list", () => {
    const ranked = rankTopDrinkHits([
      { name: "Beer", count: 1 },
      { name: "Wine", count: 1 },
      { name: "Cocktails", count: 1 },
    ]);
    expect(ranked.reduce((sum, hit) => sum + hit.percent, 0)).toBe(100);
  });
});

describe("barWidthPercent / buildDrinkBarRows", () => {
  it("gives the leader full width", () => {
    expect(barWidthPercent(40, 40)).toBe(100);
    expect(barWidthPercent(20, 40)).toBe(50);
    expect(barWidthPercent(0, 40)).toBe(0);
  });

  it("scales icon counts with relative width", () => {
    expect(iconCountForWidth(100)).toBe(DRINK_BAR_MAX_ICONS);
    expect(iconCountForWidth(50)).toBe(DRINK_BAR_MAX_ICONS / 2);
    expect(iconCountForWidth(1)).toBe(1);
    expect(iconCountForWidth(0)).toBe(0);
  });

  it("assigns amber colors and icon counts by rank", () => {
    const rows = buildDrinkBarRows([
      { name: "Beer", count: 40, percent: 40, icon: "Beer" },
      { name: "Wine", count: 20, percent: 20, icon: "Wine" },
    ]);
    expect(rows[0]!.isLeader).toBe(true);
    expect(rows[0]!.widthPercent).toBe(100);
    expect(rows[0]!.iconCount).toBe(DRINK_BAR_MAX_ICONS);
    expect(rows[0]!.color).toBe(drinkBarColor(0));
    expect(rows[1]!.widthPercent).toBe(50);
    expect(rows[1]!.iconCount).toBe(DRINK_BAR_MAX_ICONS / 2);
    expect(rows[1]!.color).toBe(drinkBarColor(1));
  });
});

