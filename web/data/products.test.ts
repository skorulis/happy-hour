import { describe, expect, it } from "vitest";
import { filterSuggestions } from "./products";

describe("filterSuggestions", () => {
  it("matches products by name substring", () => {
    const results = filterSuggestions("cockt");
    expect(results.map((p) => p.name)).toContain("cocktails");
  });

  it("matches products by synonym substring", () => {
    const results = filterSuggestions("cocktail");
    expect(results.map((p) => p.name)).toContain("cocktails");
  });

  it("matches synonym prefix before full name contains it", () => {
    // "cocktail" is a synonym of "cocktails"; typing the singular should surface it
    const results = filterSuggestions("cocktail");
    expect(results.some((p) => p.name === "cocktails")).toBe(true);
  });

  it("respects exclude set when matching via synonym", () => {
    const results = filterSuggestions(
      "cocktail",
      new Set(["cocktails"]),
    );
    expect(results.map((p) => p.name)).not.toContain("cocktails");
  });
});
