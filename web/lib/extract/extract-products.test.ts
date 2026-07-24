import { describe, expect, it } from "vitest";
import {
  extractProducts,
  validateExtractProductsRequest,
} from "./extract-products";

describe("validateExtractProductsRequest", () => {
  it("accepts title and details as strings or null", () => {
    expect(
      validateExtractProductsRequest({
        title: "$14 Cocktails",
        details: null,
      }),
    ).toEqual({
      ok: true,
      value: { title: "$14 Cocktails", details: null },
    });
  });

  it("rejects missing title", () => {
    expect(validateExtractProductsRequest({ details: "steak" })).toEqual({
      ok: false,
      error: "Missing title",
    });
  });

  it("rejects non-string title", () => {
    expect(
      validateExtractProductsRequest({ title: 14, details: null }),
    ).toEqual({
      ok: false,
      error: "Invalid title",
    });
  });
});

describe("extractProducts", () => {
  it("returns cocktails from a cocktail title with null price", () => {
    expect(
      extractProducts({ title: "$14 Cocktails", details: null }),
    ).toEqual({
      products: [{ name: "cocktails", price: null }],
    });
  });

  it("returns steak from a steak title with null price", () => {
    expect(extractProducts({ title: "$22 Steak", details: null })).toEqual({
      products: [{ name: "steak", price: null }],
    });
  });

  it("returns an empty list when no product keyword matches", () => {
    expect(
      extractProducts({ title: "$10 specials", details: "all week" }),
    ).toEqual({ products: [] });
  });

  it("returns matches from both title and details", () => {
    const result = extractProducts({
      title: "$15 Pizza Night",
      details: "happy hour on tap beer",
    });

    const names = result.products.map((product) => product.name);
    expect(names).toEqual(
      expect.arrayContaining(["pizza", "beer", "happy hour"]),
    );
    expect(result.products.every((product) => product.price === null)).toBe(
      true,
    );
  });

  it("falls back to details when title has no keyword match", () => {
    expect(
      extractProducts({
        title: "$10 specials",
        details: "half-price steak",
      }),
    ).toEqual({
      products: [{ name: "steak", price: null }],
    });
  });

  it("matches happy hour title plus drink keywords in details", () => {
    const result = extractProducts({
      title: "Happy Hour",
      details:
        "$8 Schooners & $10.50 pints of select house beers, $8 house spirits, $8 house wine, $16 aperol spritz & $19 cocktails.\nHappy hour means happy prices, so join us for great deals on your favourite drinks.",
    });

    expect(result.products.map((product) => product.name)).toEqual([
      "happy hour",
      "drinks",
      "beer",
      "cocktails",
      "schooner",
      "spirits",
      "spritz",
      "pint",
      "wine",
    ]);
    expect(result.products.every((product) => product.price === null)).toBe(
      true,
    );
  });
});
