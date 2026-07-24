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
  it("returns cocktails from a cocktail title with price", () => {
    expect(
      extractProducts({ title: "$14 Cocktails", details: null }),
    ).toEqual({
      products: [{ name: "cocktails", price: 14 }],
    });
  });

  it("returns cocktails via synonym from Cocktail Happy Hour", () => {
    const result = extractProducts({
      title: "Cocktail Happy Hour",
      details: "",
    });

    expect(result.products).toEqual(
      expect.arrayContaining([
        { name: "happy hour", price: null },
        { name: "cocktails", price: null },
      ]),
    );
    expect(result.products).toHaveLength(2);
  });

  it("returns cocktails with price via singular synonym", () => {
    expect(extractProducts({ title: "$14 Cocktail", details: null })).toEqual({
      products: [{ name: "cocktails", price: 14 }],
    });
  });

  it("returns steak from a steak title with price", () => {
    expect(extractProducts({ title: "$22 Steak", details: null })).toEqual({
      products: [{ name: "steak", price: 22 }],
    });
  });

  it("returns an empty list when no product keyword matches", () => {
    expect(
      extractProducts({ title: "$10 specials", details: "all week" }),
    ).toEqual({ products: [] });
  });

  it("returns matches from both title and details with title price", () => {
    const result = extractProducts({
      title: "$15 Pizza Night",
      details: "happy hour on tap beer",
    });

    expect(result.products).toEqual(
      expect.arrayContaining([
        { name: "pizza", price: 15 },
        { name: "night", price: null },
        { name: "beer", price: null },
        { name: "happy hour", price: null },
      ]),
    );
    expect(result.products).toHaveLength(4);
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

  it("matches happy hour title plus drink keywords and prices in details", () => {
    const result = extractProducts({
      title: "Happy Hour",
      details:
        "$8 Schooners & $10.50 pints of select house beers, $8 house spirits, $8 house wine, $16 aperol spritz & $19 cocktails.\nHappy hour means happy prices, so join us for great deals on your favourite drinks.",
    });

    expect(result.products).toEqual([
      { name: "happy hour", price: null },
      { name: "drinks", price: null },
      { name: "beer", price: null },
      { name: "cocktails", price: 19 },
      { name: "schooner", price: 8 },
      { name: "spirits", price: 8 },
      { name: "spritz", price: 16 },
      { name: "pint", price: 10.5 },
      { name: "wine", price: 8 },
    ]);
  });
});
