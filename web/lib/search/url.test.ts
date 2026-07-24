import { describe, expect, it } from "vitest";
import type { SearchFilters } from "@/components/search/SearchBar";
import {
  appendDayToPath,
  filtersToApiSearchParams,
  filtersToBrowserPath,
  filtersToBrowserSearchParams,
  legacyDaysRedirectHref,
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
    expect(parseWherePath("/map-monday")).toEqual({
      kind: "anywhere",
      map: true,
      day: 2,
    });
  });

  it("parses nearby with optional day", () => {
    expect(parseWherePath("/nearby")).toEqual({ kind: "nearby", map: false });
    expect(parseWherePath("/nearby-monday")).toEqual({
      kind: "nearby",
      map: false,
      day: 2,
    });
    expect(parseWherePath("/nearby/map")).toEqual({
      kind: "nearby",
      map: true,
    });
    expect(parseWherePath("/nearby-monday/map")).toEqual({
      kind: "nearby",
      map: true,
      day: 2,
    });
  });

  it("parses suburb where slugs with optional day", () => {
    expect(parseWherePath("/abbotsbury-2176")).toEqual({
      kind: "suburb",
      slug: "abbotsbury-2176",
      map: false,
    });
    expect(parseWherePath("/abbotsbury-2176-monday")).toEqual({
      kind: "suburb",
      slug: "abbotsbury-2176",
      map: false,
      day: 2,
    });
    expect(parseWherePath("/abbotsbury-2176/map")).toEqual({
      kind: "suburb",
      slug: "abbotsbury-2176",
      map: true,
    });
  });
});

describe("where paths", () => {
  it("builds list paths from where and day", () => {
    expect(whereToListPath(suburbWhere)).toBe("/abbotsbury-2176");
    expect(whereToListPath(suburbWhere, [2])).toBe("/abbotsbury-2176-monday");
    expect(whereToMapPath()).toBe("/map");
    expect(whereToMapPath([5])).toBe("/map");
    expect(whereToListPath(nearMeWhere)).toBe("/nearby");
    expect(whereToListPath(nearMeWhere, [2])).toBe("/nearby-monday");
    expect(whereToListPath({ kind: "anywhere" })).toBe("/");
  });
});

describe("filtersToBrowserSearchParams", () => {
  it("omits location and days query params", () => {
    const params = filtersToBrowserSearchParams(
      { ...baseFilters, where: suburbWhere },
      ["beer"],
    );
    expect(params.get("days")).toBeNull();
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

describe("searchParamsToInitialFilters", () => {
  it("keeps empty days when none are provided", () => {
    const filters = searchParamsToInitialFilters(new URLSearchParams());
    expect(filters.days).toEqual([]);
  });

  it("uses days passed from the path", () => {
    const filters = searchParamsToInitialFilters(
      new URLSearchParams(),
      { kind: "anywhere" },
      [5],
    );
    expect(filters.days).toEqual([5]);
  });
});

describe("appendDayToPath", () => {
  it("leaves the path unchanged when days are empty", () => {
    expect(appendDayToPath("/venue/foo", [])).toBe("/venue/foo");
  });

  it("appends a day suffix for a single selection", () => {
    expect(appendDayToPath("/venue/foo", [5])).toBe("/venue/foo-thursday");
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

  it("includes days for the API when selected", () => {
    const params = filtersToApiSearchParams(
      { ...baseFilters, days: [5] },
      [],
    );
    expect(params.get("days")).toBe("5");
  });

  it("omits days when the selection is empty", () => {
    const params = filtersToApiSearchParams(
      { ...baseFilters, days: [] },
      [],
    );
    expect(params.get("days")).toBeNull();
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
    ).toBe("/abbotsbury-2176-thursday");
  });

  it("preserves region base path for anywhere filters", () => {
    expect(
      filtersToBrowserPath(baseFilters, "/sydney", {
        anywhereBasePath: "/sydney",
      }),
    ).toBe("/sydney-thursday");
    expect(
      filtersToBrowserPath(
        { ...baseFilters, where: suburbWhere },
        "/sydney",
        { anywhereBasePath: "/sydney" },
      ),
    ).toBe("/abbotsbury-2176-thursday");
  });
});

describe("pathname list/map hrefs", () => {
  it("keeps map at /map and embeds day only on list paths", () => {
    const params = new URLSearchParams();
    expect(pathnameToMapHref("/abbotsbury-2176-thursday", params)).toBe("/map");
    expect(pathnameToMapHref("/nearby-thursday", params)).toBe("/map");
    expect(pathnameToListHref("/abbotsbury-2176-thursday/map", params)).toBe(
      "/abbotsbury-2176-thursday",
    );
    expect(pathnameToListHref("/map-thursday", params)).toBe("/");
  });

  it("strips legacy days query params when opening the map", () => {
    const params = new URLSearchParams("days=5");
    expect(pathnameToMapHref("/abbotsbury-2176", params)).toBe("/map");
    expect(pathnameToListHref("/map", params)).toBe("/");
  });
});

describe("legacyDaysRedirectHref", () => {
  it("redirects single-day query params into the path", () => {
    expect(
      legacyDaysRedirectHref("/nearby", new URLSearchParams("days=2")),
    ).toBe("/nearby-monday");
    expect(
      legacyDaysRedirectHref(
        "/newtown-2042",
        new URLSearchParams("days=2&q=beer"),
      ),
    ).toBe("/newtown-2042-monday?q=beer");
    expect(
      legacyDaysRedirectHref(
        "/newtown/the-venue",
        new URLSearchParams("days=2"),
      ),
    ).toBe("/newtown/the-venue-monday");
  });

  it("drops multi-day query values", () => {
    expect(
      legacyDaysRedirectHref("/nearby", new URLSearchParams("days=5,6")),
    ).toBe("/nearby");
  });

  it("returns null when days is absent", () => {
    expect(legacyDaysRedirectHref("/nearby", new URLSearchParams())).toBeNull();
  });

  it("strips days from /map without adding a day suffix", () => {
    expect(legacyDaysRedirectHref("/map", new URLSearchParams("days=5"))).toBe(
      "/map",
    );
    expect(
      legacyDaysRedirectHref("/map", new URLSearchParams("days=5&q=beer")),
    ).toBe("/map?q=beer");
  });
});

describe("legacyLocationRedirectHref", () => {
  it("redirects suburb query params to a path with day suffix", () => {
    const params = new URLSearchParams(
      "days=5&suburbId=334&suburbName=Abbotsbury&suburbPostcode=2176",
    );
    expect(legacyLocationRedirectHref("/", params)).toBe(
      "/abbotsbury-2176-thursday",
    );
  });

  it("redirects lat/lng to /nearby with day suffix", () => {
    const params = new URLSearchParams("days=5&lat=-33.87&lng=151.21");
    expect(legacyLocationRedirectHref("/", params)).toBe("/nearby-thursday");
  });

  it("redirects view=map with suburb to /map", () => {
    const params = new URLSearchParams(
      "view=map&suburbName=Abbotsbury&suburbPostcode=2176",
    );
    expect(legacyLocationRedirectHref("/", params)).toBe("/map");
  });
});
