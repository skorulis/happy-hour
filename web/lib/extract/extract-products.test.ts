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

  it("prefers title matches over details matches", () => {
    const result = extractProducts({
      title: "$15 Pizza Night",
      details: "happy hour on tap beer",
    });

    expect(result.products.map((product) => product.name)).toContain("pizza");
    expect(result.products.every((product) => product.price === null)).toBe(
      true,
    );
    expect(result.products.some((product) => product.name === "beer")).toBe(
      false,
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
});
