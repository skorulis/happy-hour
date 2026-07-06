import { describe, expect, it } from "vitest";
import {
  findMatchingProductsForDeals,
  resolveMapIconForDeals,
} from "@data/products";

describe("resolveMapIconForDeals", () => {
  it("returns Martini for cocktail deals", () => {
    expect(
      resolveMapIconForDeals([
        { title: "$14 Cocktails", details: null, conditions: null },
      ]),
    ).toBe("Martini");
  });

  it("returns Beef for steak deals", () => {
    expect(
      resolveMapIconForDeals([
        { title: "$22 STEAK NIGHT", details: null, conditions: null },
      ]),
    ).toBe("Beef");
  });

  it("returns undefined when no product keyword matches", () => {
    expect(
      resolveMapIconForDeals([
        { title: "$10 specials", details: "all week", conditions: null },
      ]),
    ).toBeUndefined();
  });

  it("prefers title matches over higher-ranked details matches", () => {
    expect(
      resolveMapIconForDeals([
        {
          title: "$15 Pizza Night",
          details: "happy hour on tap beer",
          conditions: null,
        },
      ]),
    ).toBe("Pizza");
  });

  it("falls back to details when title has no keyword match", () => {
    expect(
      resolveMapIconForDeals([
        {
          title: "$10 specials",
          details: "steak night",
          conditions: null,
        },
      ]),
    ).toBe("Beef");
  });

  it("ignores conditions for icon matching", () => {
    expect(
      resolveMapIconForDeals([
        {
          title: "$10 specials",
          details: "all week",
          conditions: "cocktails only",
        },
      ]),
    ).toBeUndefined();
  });
});

describe("findMatchingProductsForDeals", () => {
  it("prefers longer product names when ranks are equal", () => {
    const matches = findMatchingProductsForDeals([
      { title: "craft beer special", details: null, conditions: null },
    ]);

    expect(matches[0]?.name).toBe("beer");
    expect(matches.some((product) => product.name === "craft beer")).toBe(true);
    expect(resolveMapIconForDeals([
      { title: "craft beer special", details: null, conditions: null },
    ])).toBe("Beer");
  });

  it("prefers lowest rank when multiple products match", () => {
    const matches = findMatchingProductsForDeals([
      {
        title: "happy hour drinks",
        details: null,
        conditions: null,
      },
    ]);

    expect(matches[0]?.name).toBe("happy hour");
    expect(resolveMapIconForDeals([
      {
        title: "happy hour drinks",
        details: null,
        conditions: null,
      },
    ])).toBe("Clock");
  });
});
