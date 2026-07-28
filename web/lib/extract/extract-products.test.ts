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

  it("prefers fish & chips as the sole match", () => {
    expect(
      extractProducts({ title: "Fish & chips $18", details: null }),
    ).toEqual({
      products: [{ name: "fish & chips", price: 18 }],
    });
  });

  it("prefers salad over overlapping caesar cocktail for caesar salad", () => {
    expect(
      extractProducts({ title: "Caesar salad $18", details: null }),
    ).toEqual({
      products: [{ name: "salad", price: 18 }],
    });
  });

  it("returns caesar cocktail from a caesar title with price", () => {
    expect(extractProducts({ title: "$12 Caesar", details: null })).toEqual({
      products: [{ name: "caesar", price: 12 }],
    });
  });

  it("associates a price that follows the product", () => {
    expect(
      extractProducts({ title: "Happy Hour $8", details: null }),
    ).toEqual({
      products: [{ name: "happy hour", price: 8 }],
    });
  });

  it("does not treat standalone chips as a product", () => {
    const result = extractProducts({
      title: "Fish & chips and chips",
      details: null,
    });

    expect(result.products.map((product) => product.name)).toEqual([
      "fish & chips",
    ]);
  });

  it("ignores products after with on the same line", () => {
    const steak = extractProducts({
      title: "Steak with chips and salad $25",
      details: null,
    });
    expect(steak.products.map((p) => p.name)).not.toContain("salad");
    expect(steak.products.map((p) => p.name)).toContain("steak");

    expect(
      extractProducts({
        title: "Meal with crispy chips and a fresh garden salad",
        details: null,
      }).products.map((p) => p.name),
    ).not.toContain("salad");

    expect(
      extractProducts({
        title: "$30 Express lunch",
        details: "With house beer or wine",
      }).products.map((p) => p.name),
    ).toEqual(["lunch"]);
  });

  it("ignores products after w/ shorthand on the same line", () => {
    const steak = extractProducts({
      title: "Steak w/ chips and salad $25",
      details: null,
    });
    expect(steak.products.map((p) => p.name)).not.toContain("salad");
    expect(steak.products.map((p) => p.name)).toContain("steak");

    expect(
      extractProducts({
        title: "$30 Express lunch",
        details: "w/ house beer or wine",
      }).products.map((p) => p.name),
    ).toEqual(["lunch"]);
  });

  it("ignores chips in chips down", () => {
    expect(
      extractProducts({ title: "All chips down special", details: null }),
    ).toEqual({ products: [] });
  });

  it("still matches products before a with clause", () => {
    const result = extractProducts({
      title: "$8 Nachos with salad on the side",
      details: null,
    });
    expect(result.products.map((p) => p.name)).toContain("nachos");
    expect(result.products.map((p) => p.name)).not.toContain("salad");
    expect(result.products.find((p) => p.name === "nachos")?.price).toBe(8);
  });

  it("maps steak cut names to steak", () => {
    expect(
      extractProducts({ title: "Porterhouse $35", details: null }),
    ).toEqual({
      products: [{ name: "steak", price: 35 }],
    });
  });

  it("maps cheese to cheese plate", () => {
    expect(
      extractProducts({ title: "Cheese $18", details: null }),
    ).toEqual({
      products: [{ name: "cheese plate", price: 18 }],
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
        { name: "beer", price: null },
        { name: "happy hour", price: null },
      ]),
    );
    expect(result.products).toHaveLength(3);
  });

  it("ignores details matches when the title matches bottomless", () => {
    const result = extractProducts({
      title: "$49 Bottomless",
      details: "pizza, pasta, beer and cocktails",
    });

    expect(result.products).toEqual([{ name: "bottomless", price: 49 }]);
  });

  it("still matches other title products alongside bottomless", () => {
    const result = extractProducts({
      title: "Bottomless pizza $39",
      details: "includes salad and chips",
    });

    expect(result.products.map((product) => product.name).sort()).toEqual([
      "bottomless",
      "pizza",
    ]);
    expect(result.products.find((p) => p.name === "pizza")?.price).toBe(39);
    expect(result.products.find((p) => p.name === "bottomless")?.price).toBe(
      null,
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

  it("does not treat $N off as an item price", () => {
    expect(
      extractProducts({
        title: null,
        details:
          "Every tuesday at the locker room, enjoy $10 off our delicious slow cooked pork ribs.",
      }),
    ).toEqual({
      products: [{ name: "ribs", price: null }],
    });
  });

  it("still associates a real price when off is unrelated", () => {
    expect(
      extractProducts({
        title: "$10 ribs",
        details: "take-away available",
      }),
    ).toEqual({
      products: [{ name: "ribs", price: 10 }],
    });
  });

  it("does not match partial product names inside other words", () => {
    const result = extractProducts({
      title: "Happiest Hour",
      details:
        "Because this is happier than happy hour! swing past the bridgey from 4-6pm on weekdays and enjoy $7 house beer & wine and $8 house spirits.",
    });

    expect(result.products.map((product) => product.name).sort()).toEqual([
      "beer",
      "happy hour",
      "spirits",
      "wine",
    ]);
    expect(result.products.find((p) => p.name === "beer")?.price).toBe(7);
    expect(result.products.find((p) => p.name === "wine")?.price).toBe(7);
    expect(result.products.find((p) => p.name === "spirits")?.price).toBe(8);
  });

  it("shares one price across and-joined products", () => {
    const result = extractProducts({
      title: null,
      details:
        "Enjoy $5 beer and house wine in the level 2 bar.",
    });

    expect(result.products.find((p) => p.name === "beer")?.price).toBe(5);
    expect(result.products.find((p) => p.name === "wine")?.price).toBe(5);
  });

  it("shares one price across comma and and product lists", () => {
    const result = extractProducts({
      title: "$5 beer, wine and cocktails",
      details: null,
    });

    expect(result.products.find((p) => p.name === "beer")?.price).toBe(5);
    expect(result.products.find((p) => p.name === "wine")?.price).toBe(5);
    expect(result.products.find((p) => p.name === "cocktails")?.price).toBe(5);
  });

  it("shares one price across bare and-joined catalog products", () => {
    const result = extractProducts({
      title: "$5 nachos and beer all night",
      details: null,
    });

    expect(result.products.find((p) => p.name === "nachos")?.price).toBe(5);
    expect(result.products.find((p) => p.name === "beer")?.price).toBe(5);
  });

  it("does not extract top-level category products", () => {
    expect(
      extractProducts({
        title: "$5 nachos and drinks all night",
        details: null,
      }).products.map((p) => p.name),
    ).toEqual(["nachos"]);

    expect(
      extractProducts({
        title: "Food specials and events tonight",
        details: null,
      }).products.map((p) => p.name),
    ).toEqual([]);
  });

  it("does not share a price past a with clause", () => {
    const result = extractProducts({
      title: "$12 burger with fries",
      details: null,
    });

    expect(result.products.find((p) => p.name === "burger")?.price).toBe(12);
    expect(result.products.map((p) => p.name)).not.toContain("fries");
  });

  it("does not share a price across separate dollar amounts", () => {
    const result = extractProducts({
      title: "Happy Hour",
      details:
        "$8 Schooners & $10.50 pints of select house beers, $8 house spirits, $8 house wine, $16 aperol spritz & $19 cocktails.\nHappy hour means happy prices, so join us for great deals on your favourite drinks.",
    });

    expect(result.products).toEqual([
      { name: "happy hour", price: null },
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
