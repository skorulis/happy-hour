import { describe, expect, it } from "vitest";
import type { SearchFilters } from "@/components/search/SearchBar";
import { currentCalendarWeekday } from "./schedule";
import {
  appendDaysParam,
  effectiveSearchDays,
  filtersToApiSearchParams,
  filtersToBrowserPath,
  filtersToBrowserSearchParams,
  legacyLocationRedirectHref,
  parseWherePath,
  pathnameToListHref,
  pathnameToMapHref,
  searchParamsToInitialFilters,
  whereToListPath,
  whereToMapPath,
} from "./url";

const suburbWhere = {
  kind: "suburb" as const,
  id: 334,
  suburb: { id: 334, name: "Abbotsbury", postcode: "2176" },
};

const nearMeWhere = {
  kind: "nearMe" as const,
  lat: -33.87,
  lng: 151.21,
};

const baseFilters: SearchFilters = {
  days: [5],
  timeRange: null,
  where: { kind: "anywhere" },
  what: [],
};

describe("parseWherePath", () => {
  it("parses anywhere and map", () => {
    expect(parseWherePath("/")).toEqual({ kind: "anywhere", map: false });
    expect(parseWherePath("/map")).toEqual({ kind: "anywhere", map: true });
  });

  it("parses nearby", () => {
    expect(parseWherePath("/nearby")).toEqual({ kind: "nearby", map: false });
    expect(parseWherePath("/nearby/map")).toEqual({
      kind: "nearby",
      map: true,
    });
  });

  it("parses suburb where slugs", () => {
    expect(parseWherePath("/abbotsbury-2176")).toEqual({
      kind: "suburb",
      slug: "abbotsbury-2176",
      map: false,
    });
    expect(parseWherePath("/abbotsbury-2176/map")).toEqual({
      kind: "suburb",
      slug: "abbotsbury-2176",
      map: true,
    });
  });
});

describe("where paths", () => {
  it("builds list paths from where and always uses /map for map", () => {
    expect(whereToListPath(suburbWhere)).toBe("/abbotsbury-2176");
    expect(whereToMapPath(suburbWhere)).toBe("/map");
    expect(whereToListPath(nearMeWhere)).toBe("/nearby");
    expect(whereToMapPath(nearMeWhere)).toBe("/map");
    expect(whereToListPath({ kind: "anywhere" })).toBe("/");
    expect(whereToMapPath({ kind: "anywhere" })).toBe("/map");
  });
});

describe("filtersToBrowserSearchParams", () => {
  it("omits location query params", () => {
    const params = filtersToBrowserSearchParams(
      { ...baseFilters, where: suburbWhere },
      ["beer"],
    );
    expect(params.get("days")).toBe("5");
    expect(params.get("q")).toBe("beer");
    expect(params.get("suburbId")).toBeNull();
    expect(params.get("suburbName")).toBeNull();
    expect(params.get("lat")).toBeNull();
  });

  it("omits empty days from the browser URL", () => {
    const params = filtersToBrowserSearchParams(
      { ...baseFilters, days: [] },
      [],
    );
    expect(params.get("days")).toBeNull();
  });
});

describe("effectiveSearchDays", () => {
  it("defaults empty selection to today", () => {
    expect(effectiveSearchDays([])).toEqual([currentCalendarWeekday()]);
  });

  it("passes through an explicit selection", () => {
    expect(effectiveSearchDays([5, 6])).toEqual([5, 6]);
  });
});

describe("searchParamsToInitialFilters", () => {
  it("keeps empty days when the URL has no days param", () => {
    const filters = searchParamsToInitialFilters(new URLSearchParams());
    expect(filters.days).toEqual([]);
  });

  it("parses an explicit days param", () => {
    const filters = searchParamsToInitialFilters(
      new URLSearchParams("days=5,6"),
    );
    expect(filters.days).toEqual([5, 6]);
  });
});

describe("appendDaysParam", () => {
  it("appends today when days are empty", () => {
    expect(appendDaysParam("/venue/foo", [])).toBe(
      `/venue/foo?days=${currentCalendarWeekday()}`,
    );
  });

  it("appends an explicit selection", () => {
    expect(appendDaysParam("/venue/foo", [5])).toBe("/venue/foo?days=5");
  });
});

describe("filtersToApiSearchParams", () => {
  it("includes suburbId for suburb filters", () => {
    const params = filtersToApiSearchParams(
      { ...baseFilters, where: suburbWhere },
      [],
    );
    expect(params.get("suburbId")).toBe("334");
  });

  it("includes lat/lng for ready near-me filters", () => {
    const params = filtersToApiSearchParams(
      { ...baseFilters, where: nearMeWhere },
      [],
    );
    expect(params.get("lat")).toBe("-33.87");
    expect(params.get("lng")).toBe("151.21");
  });

  it("omits lat/lng while near-me is pending", () => {
    const params = filtersToApiSearchParams(
      { ...baseFilters, where: { kind: "nearMe" } },
      [],
    );
    expect(params.get("lat")).toBeNull();
    expect(params.get("lng")).toBeNull();
  });

  it("sends today when days are empty", () => {
    const params = filtersToApiSearchParams(
      { ...baseFilters, days: [] },
      [],
    );
    expect(params.get("days")).toBe(String(currentCalendarWeekday()));
  });
});

describe("filtersToBrowserPath", () => {
  it("uses list where path, and /map when already on map", () => {
    expect(
      filtersToBrowserPath({ ...baseFilters, where: suburbWhere }, "/map"),
    ).toBe("/map");
    expect(
      filtersToBrowserPath({ ...baseFilters, where: nearMeWhere }, "/map"),
    ).toBe("/map");
    expect(
      filtersToBrowserPath({ ...baseFilters, where: suburbWhere }, "/"),
    ).toBe("/abbotsbury-2176");
  });
});

describe("pathname list/map hrefs", () => {
  it("always maps to /map and restores where when leaving nested map paths", () => {
    const params = new URLSearchParams("days=5");
    expect(pathnameToMapHref("/abbotsbury-2176", params)).toBe("/map?days=5");
    expect(pathnameToMapHref("/nearby", params)).toBe("/map?days=5");
    expect(pathnameToMapHref("/", params)).toBe("/map?days=5");
    expect(pathnameToListHref("/abbotsbury-2176/map", params)).toBe(
      "/abbotsbury-2176?days=5",
    );
    expect(pathnameToListHref("/map", params)).toBe("/?days=5");
  });
});

describe("legacyLocationRedirectHref", () => {
  it("redirects suburb query params to a path", () => {
    const params = new URLSearchParams(
      "days=5&suburbId=334&suburbName=Abbotsbury&suburbPostcode=2176",
    );
    expect(legacyLocationRedirectHref("/", params)).toBe(
      "/abbotsbury-2176?days=5",
    );
  });

  it("redirects lat/lng to /nearby", () => {
    const params = new URLSearchParams("days=5&lat=-33.87&lng=151.21");
    expect(legacyLocationRedirectHref("/", params)).toBe("/nearby?days=5");
  });

  it("redirects view=map with suburb to /map", () => {
    const params = new URLSearchParams(
      "view=map&suburbName=Abbotsbury&suburbPostcode=2176",
    );
    expect(legacyLocationRedirectHref("/", params)).toBe("/map");
  });
});
