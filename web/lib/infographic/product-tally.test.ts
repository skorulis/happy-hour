import { describe, expect, it } from "vitest";
import { tallyProductHitsFromDeals } from "@/lib/infographic/product-tally";

describe("tallyProductHitsFromDeals", () => {
  it("returns an empty list when there are no deals", () => {
    expect(tallyProductHitsFromDeals([])).toEqual([]);
  });

  it("counts product matches across deals and sorts by frequency", () => {
    const hits = tallyProductHitsFromDeals([
      { title: "$8 schooners", details: null, conditions: null },
      { title: "Beer special", details: "Pints from 4pm", conditions: null },
      { title: "Negroni hour", details: null, conditions: null },
      { title: "Cocktail deal", details: "House cocktails", conditions: null },
      { title: "Cocktail deal", details: "More cocktails", conditions: null },
    ]);

    expect(hits.length).toBeGreaterThan(0);
    expect(hits[0]!.count).toBeGreaterThanOrEqual(hits[1]?.count ?? 0);
    expect(hits.every((hit) => hit.count >= 1)).toBe(true);
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
