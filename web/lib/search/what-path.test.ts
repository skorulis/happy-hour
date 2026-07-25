import { describe, expect, it } from "vitest";
import {
  appendFiltersToPath,
  encodeFilterSegment,
  parseFilterSegment,
  pathSlugToWhatToken,
  splitWhatForPath,
  stripFiltersFromPath,
  whatSlug,
} from "./what-path";

describe("whatSlug", () => {
  it("compacts tokens by removing non-alphanumeric characters", () => {
    expect(whatSlug("happy hour")).toBe("happyhour");
    expect(whatSlug("2 for 1")).toBe("2for1");
    expect(whatSlug("fish & chips")).toBe("fishchips");
    expect(whatSlug("Beer")).toBe("beer");
  });
});

describe("pathSlugToWhatToken", () => {
  it("round-trips catalog product names", () => {
    expect(pathSlugToWhatToken("beer")).toBe("beer");
    expect(pathSlugToWhatToken("happyhour")).toBe("happy hour");
    expect(pathSlugToWhatToken("fishchips")).toBe("fish & chips");
    expect(pathSlugToWhatToken("2for1")).toBe("2 for 1");
  });

  it("resolves synonyms to the canonical product name", () => {
    expect(pathSlugToWhatToken("cocktail")).toBe("cocktails");
  });

  it("rejects unknown slugs", () => {
    expect(pathSlugToWhatToken("thelocal")).toBeNull();
    expect(pathSlugToWhatToken("weekday")).toBeNull();
  });
});

describe("splitWhatForPath", () => {
  it("splits catalog tokens from free-text", () => {
    expect(splitWhatForPath(["beer", "obscure snack", "happy hour"])).toEqual({
      pathTokens: ["beer", "happy hour"],
      queryTokens: ["obscure snack"],
    });
  });
});

describe("encodeFilterSegment / parseFilterSegment", () => {
  it("encodes day only, what only, and day+what", () => {
    expect(encodeFilterSegment(4, [])).toBe("wednesday");
    expect(encodeFilterSegment(null, ["beer"])).toBe("beer");
    expect(encodeFilterSegment(4, ["beer", "happy hour"])).toBe(
      "wednesday-beer-happyhour",
    );
    expect(encodeFilterSegment(null, [])).toBeNull();
  });

  it("parses day only, what only, and day+what", () => {
    expect(parseFilterSegment("wednesday")).toEqual({
      day: 4,
      what: [],
    });
    expect(parseFilterSegment("cocktails")).toEqual({
      day: null,
      what: ["cocktails"],
    });
    expect(parseFilterSegment("wednesday-beer-happyhour")).toEqual({
      day: 4,
      what: ["beer", "happy hour"],
    });
  });

  it("rejects venue-like segments", () => {
    expect(parseFilterSegment("the-local")).toBeNull();
    expect(parseFilterSegment("wednesday-the-local")).toBeNull();
  });
});

describe("stripFiltersFromPath / appendFiltersToPath", () => {
  it("strips trailing filter segments", () => {
    expect(stripFiltersFromPath("/sydney/wednesday-beer")).toEqual({
      base: "/sydney",
      day: 4,
      what: ["beer"],
    });
    expect(stripFiltersFromPath("/nearby/cocktails")).toEqual({
      base: "/nearby",
      day: null,
      what: ["cocktails"],
    });
    expect(stripFiltersFromPath("/sydney-cbd-2000-wednesday")).toEqual({
      base: "/sydney-cbd-2000",
      day: 4,
      what: [],
    });
  });

  it("does not treat a sole segment as a filter", () => {
    expect(stripFiltersFromPath("/beer")).toEqual({
      base: "/beer",
      day: null,
      what: [],
    });
  });

  it("appends filter segments and never touches /map", () => {
    expect(appendFiltersToPath("/sydney", [4], ["beer"])).toBe(
      "/sydney/wednesday-beer",
    );
    expect(appendFiltersToPath("/nearby", [], ["happy hour"])).toBe(
      "/nearby/happyhour",
    );
    expect(appendFiltersToPath("/map", [4], ["beer"])).toBe("/map");
    expect(appendFiltersToPath("/", [4], ["beer"])).toBe("/");
  });

  it("replaces an existing filter segment", () => {
    expect(
      appendFiltersToPath("/sydney/wednesday-beer", [5], ["cocktails"]),
    ).toBe("/sydney/thursday-cocktails");
    expect(appendFiltersToPath("/sydney/wednesday-beer", [], [])).toBe(
      "/sydney",
    );
  });

  it("leaves free-text what out of the path", () => {
    expect(
      appendFiltersToPath("/sydney", [4], ["beer", "obscure snack"]),
    ).toBe("/sydney/wednesday-beer");
  });
});
