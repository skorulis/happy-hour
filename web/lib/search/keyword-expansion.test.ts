import { describe, expect, it } from "vitest";
import {
  expandKeywordGroups,
  expandKeywords,
  expandSearchTerms,
} from "@data/products";
import { filtersToApiSearchParams, parseWhatTokens, DEFAULT_SEARCH_FILTERS } from "./url";

describe("expandKeywords", () => {
  it("includes grouped keywords for a single selection", () => {
    const expanded = expandKeywords(["beer"]);
    expect(expanded).toEqual(
      expect.arrayContaining([
        "beer",
        "schooner",
        "pint",
        "pot",
        "jugs",
        "guinness",
        "craft beer",
      ]),
    );
    expect(expanded).toHaveLength(7);
  });

  it("expands groups recursively", () => {
    const expanded = expandKeywords(["drinks"]);
    expect(expanded).toEqual(
      expect.arrayContaining([
        "drinks",
        "beer",
        "cocktails",
        "wine",
        "whiskey",
        "champagne",
        "sake",
        "soju",
        "seltzer",
        "cider",
        "schooner",
        "pint",
        "pot",
        "jugs",
        "guinness",
        "craft beer",
        "spritz",
      ]),
    );
    expect(expanded).toHaveLength(17);
  });

  it("deduplicates shared descendants", () => {
    const expanded = expandKeywords(["beer", "jugs"]);
    expect(expanded).toEqual(
      expect.arrayContaining([
        "beer",
        "jugs",
        "schooner",
        "pint",
        "pot",
        "guinness",
        "craft beer",
      ]),
    );
    expect(expanded).toHaveLength(7);
  });

  it("merges expansions from multiple selected tags for OR search", () => {
    const expanded = expandKeywords(["beer", "steak"]);
    expect(expanded).toEqual(
      expect.arrayContaining([
        "beer",
        "steak",
        "schooner",
        "pint",
        "pot",
        "jugs",
        "guinness",
        "craft beer",
      ]),
    );
    expect(expanded).toHaveLength(8);
  });
});

describe("expandSearchTerms", () => {
  it("includes product synonyms for FTS", () => {
    const expanded = expandSearchTerms(["happy hour"]);
    expect(expanded).toEqual(
      expect.arrayContaining([
        "happy hour",
        "golden hour",
        "happiest hour",
        "mates rates",
      ]),
    );
    expect(expanded[0]).toBe("happy hour");
  });

  it("still expands groups before adding synonyms", () => {
    const expanded = expandSearchTerms(["beer"]);
    expect(expanded).toEqual(
      expect.arrayContaining(["beer", "schooner", "pint", "guinness"]),
    );
  });
});

describe("expandKeywordGroups", () => {
  it("keeps each selected token in its own group", () => {
    expect(expandKeywordGroups(["beer", "burger"])).toEqual([
      ["beer", "schooner", "pint", "pot", "jugs", "guinness", "craft beer"],
      ["burger"],
    ]);
  });
});

describe("parseWhatTokens", () => {
  it("splits comma-separated chips", () => {
    expect(parseWhatTokens("beer,burger")).toEqual(["beer", "burger"]);
    expect(parseWhatTokens("happy hour,beer")).toEqual(["happy hour", "beer"]);
  });
});

describe("filtersToApiSearchParams", () => {
  it("sends comma-separated what tokens to the API", () => {
    const params = filtersToApiSearchParams(DEFAULT_SEARCH_FILTERS, [
      "beer",
      "burger",
    ]);

    expect(params.get("q")).toBe("beer,burger");
  });
});
