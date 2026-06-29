import { describe, expect, it } from "vitest";
import { expandKeywordGroups, expandKeywords } from "@data/products";
import { filtersToApiSearchParams, parseWhatTokens, DEFAULT_SEARCH_FILTERS } from "./url";

describe("expandKeywords", () => {
  it("includes grouped keywords for a single selection", () => {
    const expanded = expandKeywords(["beer"]);
    expect(expanded).toEqual(
      expect.arrayContaining(["beer", "schooner", "pint", "jugs"]),
    );
    expect(expanded).toHaveLength(4);
  });

  it("expands groups recursively", () => {
    const expanded = expandKeywords(["drinks"]);
    expect(expanded).toEqual(
      expect.arrayContaining([
        "drinks",
        "beer",
        "cocktails",
        "wine",
        "schooner",
        "pint",
        "jugs",
        "negroni",
        "martini",
        "spritz",
      ]),
    );
    expect(expanded).toHaveLength(10);
  });

  it("deduplicates shared descendants", () => {
    const expanded = expandKeywords(["beer", "jugs"]);
    expect(expanded).toEqual(
      expect.arrayContaining(["beer", "schooner", "pint", "jugs"]),
    );
    expect(expanded).toHaveLength(4);
  });

  it("merges expansions from multiple selected tags for OR search", () => {
    const expanded = expandKeywords(["beer", "steak"]);
    expect(expanded).toEqual(
      expect.arrayContaining([
        "beer",
        "schooner",
        "pint",
        "jugs",
        "steak",
        "porterhouse",
        "rump",
        "sirloin",
      ]),
    );
    expect(expanded).toHaveLength(8);
  });
});

describe("expandKeywordGroups", () => {
  it("keeps each selected token in its own group", () => {
    expect(expandKeywordGroups(["beer", "burger"])).toEqual([
      ["beer", "schooner", "pint", "jugs"],
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
