import type { SearchFilters } from "@/components/search/SearchBar";
import type { TimeRange } from "@/components/search/DayPicker";
import type { WhereFilter } from "@/components/search/SuburbSelect";
import { boundsToApiParams, type MapBounds } from "@/lib/search/bounds";
import {
  appendDayToPath,
  daysFromBrowserUrl,
  stripDaySuffix,
} from "@/lib/search/day-path";
import {
  NEARBY_WHERE_SLUG,
  suburbWherePath,
  suburbWhereSlug,
} from "@/lib/search/slugs";
import {
  appendFiltersToPath,
  parseFilterSegment,
  splitWhatForPath,
  stripFiltersFromPath,
} from "@/lib/search/what-path";

export const DEFAULT_SEARCH_FILTERS: SearchFilters = {
  days: [],
  timeRange: null,
  where: { kind: "anywhere" },
  what: [],
};

export type WherePathKind =
  | { kind: "anywhere"; map: boolean; day?: number; what?: string[] }
  | { kind: "nearby"; map: boolean; day?: number; what?: string[] }
  | {
      kind: "suburb";
      slug: string;
      map: boolean;
      day?: number;
      what?: string[];
    };

function withOptionalFilters<T extends WherePathKind>(
  value: T,
  day: number | null,
  what: string[],
): T {
  let next: T = value;
  if (day !== null) {
    next = { ...next, day };
  }
  if (what.length > 0) {
    next = { ...next, what };
  }
  return next;
}

export function stripLocationParams(params: URLSearchParams): URLSearchParams {
  const filtered = new URLSearchParams(params.toString());
  filtered.delete("view");
  filtered.delete("suburbId");
  filtered.delete("suburbName");
  filtered.delete("suburbPostcode");
  filtered.delete("lat");
  filtered.delete("lng");
  filtered.delete("days");
  return filtered;
}

/** Drop catalog tokens from `q` after they have been moved into the path. */
export function stripCatalogWhatFromParams(
  params: URLSearchParams,
): URLSearchParams {
  const filtered = new URLSearchParams(params.toString());
  const q = filtered.get("q");
  if (q === null) {
    return filtered;
  }
  const { queryTokens } = splitWhatForPath(parseWhatTokens(q));
  if (queryTokens.length === 0) {
    filtered.delete("q");
  } else {
    filtered.set("q", queryTokens.join(","));
  }
  return filtered;
}

export function parseWherePath(pathname: string): WherePathKind {
  const segments = pathname.split("/").filter(Boolean);

  if (segments.length === 0) {
    return { kind: "anywhere", map: false };
  }

  const first = stripDaySuffix(segments[0]!);
  let day: number | null = first.day;
  let what: string[] = [];
  let rest = segments.slice(1);

  if (rest.length > 0) {
    const filter = parseFilterSegment(rest[0]!);
    if (filter) {
      day = filter.day ?? day;
      what = filter.what;
      rest = rest.slice(1);
    }
  }

  const isMapSegment = rest[0] === "map";

  if (segments.length === 1 && first.base === "map") {
    return withOptionalFilters(
      { kind: "anywhere", map: true },
      first.day,
      [],
    );
  }

  if (first.base === NEARBY_WHERE_SLUG) {
    if (rest.length === 0 || (rest.length === 1 && isMapSegment)) {
      return withOptionalFilters(
        {
          kind: "nearby",
          map: isMapSegment,
        },
        day,
        what,
      );
    }
    return { kind: "anywhere", map: false };
  }

  if (rest.length === 0 || (rest.length === 1 && isMapSegment)) {
    return withOptionalFilters(
      { kind: "suburb", slug: first.base, map: isMapSegment },
      day,
      what,
    );
  }

  return { kind: "anywhere", map: false };
}

export function whereToListPath(
  where: WhereFilter,
  days: number[] = [],
  what: string[] = [],
): string {
  let path: string;
  if (where.kind === "suburb") {
    path = suburbWherePath(where.suburb.name, where.suburb.postcode);
  } else if (where.kind === "nearMe") {
    path = `/${NEARBY_WHERE_SLUG}`;
  } else {
    path = "/";
  }
  return appendFiltersToPath(path, days, what);
}

/**
 * Map is always `/map` — viewport bounds, not where.
 * Day selection is kept in session map-entry storage (not the URL) so Google
 * Maps referrer checks stay on an authorized path.
 */
export function whereToMapPath(): string {
  return "/map";
}

export function filtersToBrowserPath(
  filters: SearchFilters,
  pathname: string,
  options?: { anywhereBasePath?: string },
): string {
  const parsed = parseWherePath(pathname);
  if (parsed.map) {
    return whereToMapPath();
  }
  if (filters.where.kind === "anywhere" && options?.anywhereBasePath) {
    return appendFiltersToPath(
      options.anywhereBasePath,
      filters.days,
      filters.what,
    );
  }
  return whereToListPath(filters.where, filters.days, filters.what);
}

function hrefWithQuery(path: string, params: URLSearchParams): string {
  const qs = params.toString();
  return qs ? `${path}?${qs}` : path;
}

/**
 * Map href from a list pathname. The map URL never carries what (catalog or
 * free-text); it is preserved on the session map-entry instead, mirroring how
 * the day is kept off `/map`.
 */
export function pathnameToMapHref(
  pathname: string,
  params: URLSearchParams,
): string {
  const cleaned = stripLocationParams(params);
  cleaned.delete("q");
  return hrefWithQuery(whereToMapPath(), cleaned);
}

export function pathnameToListHref(
  pathname: string,
  params: URLSearchParams,
): string {
  const parsed = parseWherePath(pathname);
  const day =
    parsed.day !== undefined
      ? [parsed.day]
      : daysFromBrowserUrl(pathname, params);
  const pathWhat = parsed.what ?? stripFiltersFromPath(pathname).what;
  const queryWhat = parseWhatParam(params.get("q"));
  const what = [...pathWhat];
  for (const token of queryWhat) {
    if (!what.some((item) => item.toLowerCase() === token.toLowerCase())) {
      what.push(token);
    }
  }

  let path: string;
  if (parsed.kind === "nearby") {
    path = `/${NEARBY_WHERE_SLUG}`;
  } else if (parsed.kind === "suburb") {
    path = `/${parsed.slug}`;
  } else {
    path = "/";
  }

  const withFilters = appendFiltersToPath(path, day, what);
  const cleaned = stripCatalogWhatFromParams(stripLocationParams(params));
  return hrefWithQuery(withFilters, cleaned);
}

/** Legacy helper: map href from query params alone (anywhere). */
export function searchParamsToMapHref(params: URLSearchParams): string {
  return pathnameToMapHref("/", params);
}

/** Legacy helper: list href from query params alone (anywhere). */
export function searchParamsToListHref(params: URLSearchParams): string {
  return pathnameToListHref("/map", params);
}

function parseWhatParam(value: string | null): string[] {
  if (value === null || value.trim() === "") {
    return [];
  }

  return parseWhatTokens(value);
}

export function parseDaysParam(value: string | null): number[] {
  if (value === null || value.trim() === "") {
    return [];
  }

  const days = value
    .split(",")
    .map((part) => Number(part.trim()))
    .filter((day) => Number.isFinite(day) && day >= 1 && day <= 7);

  return days;
}

/** @deprecated Prefer appendDayToPath for browser URLs. Kept for API-style links. */
export function appendDaysParam(path: string, days: number[]): string {
  if (days.length === 0) {
    return path;
  }
  return `${path}?days=${days.join(",")}`;
}

export { appendDayToPath, appendFiltersToPath };

export function initialVenueDay(days: number[]): number | null {
  return days.length === 1 ? days[0]! : null;
}

/**
 * Redirect legacy `?days=` and catalog `?q=` tokens into the filter path segment.
 * Free-text `q` tokens remain as query params. `/map` keeps `q` and never gets
 * a filter segment. Returns null when no redirect is needed.
 */
export function legacyDaysRedirectHref(
  pathname: string,
  params: URLSearchParams,
): string | null {
  const hasDays = params.has("days");
  const queryWhat = parseWhatParam(params.get("q"));
  const { pathTokens, queryTokens } = splitWhatForPath(queryWhat);
  const needsWhatRedirect = pathTokens.length > 0 && pathname !== "/map";

  if (!hasDays && !needsWhatRedirect) {
    return null;
  }

  // Home has no where segment to attach filters to — leave catalog q as-is.
  const segments = pathname.split("/").filter(Boolean);
  if (segments.length === 0) {
    if (!hasDays) {
      return null;
    }
    const cleaned = new URLSearchParams(params.toString());
    cleaned.delete("days");
    const parsedDays = parseDaysParam(params.get("days"));
    const day = parsedDays.length === 1 ? parsedDays : [];
    return hrefWithQuery(appendDayToPath("/", day), cleaned);
  }

  const parsedDays = hasDays ? parseDaysParam(params.get("days")) : [];
  const dayFromQuery = parsedDays.length === 1 ? parsedDays : [];
  const cleaned = new URLSearchParams(params.toString());
  cleaned.delete("days");
  if (queryTokens.length === 0) {
    cleaned.delete("q");
  } else {
    cleaned.set("q", queryTokens.join(","));
  }

  const stripped = stripFiltersFromPath(pathname);
  const existingDay =
    dayFromQuery.length === 1
      ? dayFromQuery
      : stripped.day !== null
        ? [stripped.day]
        : [];
  const existingWhat = stripped.what;
  const mergedWhat = [...existingWhat];
  for (const token of pathTokens) {
    if (!mergedWhat.some((item) => item.toLowerCase() === token.toLowerCase())) {
      mergedWhat.push(token);
    }
  }

  // Canonical map URL never carries a filter segment or what; the map entry
  // owns what once the client takes over.
  if (stripped.base === "/map") {
    cleaned.delete("q");
    return hrefWithQuery("/map", cleaned);
  }

  const pathSegments = stripped.base.split("/").filter(Boolean);
  const endsWithMap =
    pathSegments.length >= 2 && pathSegments[pathSegments.length - 1] === "map";
  const wherePath = endsWithMap
    ? `/${pathSegments.slice(0, -1).join("/")}`
    : stripped.base;
  const withFilters = appendFiltersToPath(wherePath, existingDay, mergedWhat);

  if (endsWithMap) {
    return hrefWithQuery(`${withFilters}/map`, cleaned);
  }

  return hrefWithQuery(withFilters, cleaned);
}

export function parseTimeRange(
  startMinuteParam: string | null,
  endMinuteParam: string | null,
): TimeRange {
  const hasStart =
    startMinuteParam !== null && startMinuteParam !== "";
  const hasEnd = endMinuteParam !== null && endMinuteParam !== "";

  if (!hasStart && !hasEnd) {
    return null;
  }

  const startMinute = hasStart ? Number(startMinuteParam) : undefined;
  const endMinute = hasEnd ? Number(endMinuteParam) : undefined;

  if (
    hasStart &&
    (!Number.isFinite(startMinute) ||
      startMinute! < 0 ||
      startMinute! > 1439)
  ) {
    return null;
  }

  if (
    hasEnd &&
    (!Number.isFinite(endMinute) || endMinute! < 1 || endMinute! > 1440)
  ) {
    return null;
  }

  if (
    hasStart &&
    hasEnd &&
    endMinute! < startMinute!
  ) {
    return null;
  }

  return {
    ...(hasStart ? { startMinute: startMinute! } : {}),
    ...(hasEnd ? { endMinute: endMinute! } : {}),
  };
}

export function whatToQuery(what: string[]): string {
  return what.join(",");
}

export function parseWhatTokens(query: string): string[] {
  return query
    .split(",")
    .map((part) => part.trim())
    .filter((part) => part.length > 0);
}

export function whatTokensEqual(a: string[], b: string[]): boolean {
  if (a.length !== b.length) {
    return false;
  }

  return a.every((token, index) => token === b[index]);
}

export function whereFilterKey(where: WhereFilter): string {
  if (where.kind === "anywhere") {
    return "anywhere";
  }
  if (where.kind === "nearMe") {
    if (where.lat === undefined || where.lng === undefined) {
      return "near:pending";
    }
    return `near:${where.lat},${where.lng}`;
  }
  return `suburb:${where.id}:${where.suburb.name}:${where.suburb.postcode ?? ""}`;
}

export function timeRangeKey(timeRange: TimeRange): string {
  if (!timeRange) {
    return "";
  }
  const start = timeRange.startMinute ?? "";
  const end = timeRange.endMinute ?? "";
  return `${start}-${end}`;
}

export function searchParamsEqual(a: string, b: string): boolean {
  const left = new URLSearchParams(a);
  const right = new URLSearchParams(b);
  const keys = new Set([...left.keys(), ...right.keys()]);

  for (const key of keys) {
    const leftValues = left.getAll(key).sort();
    const rightValues = right.getAll(key).sort();

    if (leftValues.length !== rightValues.length) {
      return false;
    }

    for (let index = 0; index < leftValues.length; index++) {
      if (leftValues[index] !== rightValues[index]) {
        return false;
      }
    }
  }

  return true;
}

/** Browser URL query params — time always; what only when not path-encoded. */
export function filtersToBrowserSearchParams(
  filters: SearchFilters,
  what: string[],
  options?: { pathEncodeWhat?: boolean },
): URLSearchParams {
  const params = new URLSearchParams();

  if (filters.timeRange) {
    if (filters.timeRange.startMinute !== undefined) {
      params.set("startMinute", String(filters.timeRange.startMinute));
    }
    if (filters.timeRange.endMinute !== undefined) {
      params.set("endMinute", String(filters.timeRange.endMinute));
    }
  }

  const pathEncodeWhat = options?.pathEncodeWhat ?? true;
  if (pathEncodeWhat) {
    const { queryTokens } = splitWhatForPath(what);
    if (queryTokens.length > 0) {
      params.set("q", queryTokens.join(","));
    }
  } else if (what.length > 0) {
    params.set("q", what.join(","));
  }

  return params;
}

/** @deprecated Use filtersToBrowserSearchParams for browser URLs. */
export function filtersToSearchParams(
  filters: SearchFilters,
  what: string[],
): URLSearchParams {
  return filtersToBrowserSearchParams(filters, what);
}

export function searchParamsToFilters(
  params: URLSearchParams,
  where: WhereFilter = { kind: "anywhere" },
  days: number[] = [],
  pathWhat: string[] = [],
): SearchFilters {
  const queryWhat = parseWhatParam(params.get("q"));
  const what = [...pathWhat];
  for (const token of queryWhat) {
    if (!what.some((item) => item.toLowerCase() === token.toLowerCase())) {
      what.push(token);
    }
  }
  return {
    days,
    timeRange: parseTimeRange(
      params.get("startMinute"),
      params.get("endMinute"),
    ),
    where,
    what,
  };
}

/**
 * Filters for the main search page. Days and catalog what come from the path;
 * free-text what comes from `?q=`.
 */
export function searchParamsToInitialFilters(
  params: URLSearchParams,
  where: WhereFilter = { kind: "anywhere" },
  days: number[] = [],
  pathWhat: string[] = [],
): SearchFilters {
  return searchParamsToFilters(params, where, days, pathWhat);
}

/** API query params — includes suburbId or lat/lng for the deals endpoint. */
export function filtersToApiSearchParams(
  filters: SearchFilters,
  what: string[],
): URLSearchParams {
  const params = filtersToBrowserSearchParams(filters, what, {
    pathEncodeWhat: false,
  });

  if (filters.days.length > 0) {
    params.set("days", filters.days.join(","));
  }

  if (filters.where.kind === "suburb") {
    params.set("suburbId", String(filters.where.id));
  } else if (
    filters.where.kind === "nearMe" &&
    filters.where.lat !== undefined &&
    filters.where.lng !== undefined
  ) {
    params.set("lat", String(filters.where.lat));
    params.set("lng", String(filters.where.lng));
  }

  return params;
}

export function filtersToMapApiSearchParams(
  filters: SearchFilters,
  what: string[],
  bounds: MapBounds,
): URLSearchParams {
  const params = new URLSearchParams();

  if (filters.days.length > 0) {
    params.set("days", filters.days.join(","));
  }
  if (filters.timeRange) {
    if (filters.timeRange.startMinute !== undefined) {
      params.set("startMinute", String(filters.timeRange.startMinute));
    }
    if (filters.timeRange.endMinute !== undefined) {
      params.set("endMinute", String(filters.timeRange.endMinute));
    }
  }
  if (what.length > 0) {
    params.set("q", what.join(","));
  }

  for (const [key, value] of boundsToApiParams(bounds).entries()) {
    params.set(key, value);
  }

  return params;
}

export type LegacyLocationRedirect =
  | { type: "suburb"; slug: string }
  | { type: "nearby" }
  | null;

export function legacyLocationFromSearchParams(
  params: URLSearchParams,
): LegacyLocationRedirect {
  const suburbName = params.get("suburbName");
  const suburbPostcode = params.get("suburbPostcode");
  const suburbIdParam = params.get("suburbId");

  if (suburbName && suburbName.length > 0) {
    return {
      type: "suburb",
      slug: suburbWhereSlug(suburbName, suburbPostcode),
    };
  }

  if (suburbIdParam !== null && suburbIdParam !== "") {
    // Name missing — cannot build a slug; fall through to nearby/anywhere.
  }

  const latParam = params.get("lat");
  const lngParam = params.get("lng");
  if (
    latParam !== null &&
    latParam !== "" &&
    lngParam !== null &&
    lngParam !== ""
  ) {
    const lat = Number(latParam);
    const lng = Number(lngParam);
    if (
      Number.isFinite(lat) &&
      Number.isFinite(lng) &&
      lat >= -90 &&
      lat <= 90 &&
      lng >= -180 &&
      lng <= 180
    ) {
      return { type: "nearby" };
    }
  }

  return null;
}

export function legacyLocationRedirectHref(
  pathname: string,
  params: URLSearchParams,
): string | null {
  const legacy = legacyLocationFromSearchParams(params);
  if (!legacy) {
    return null;
  }

  const parsed = parseWherePath(pathname);
  const isMap =
    params.get("view") === "map" || parsed.map || pathname === "/map";

  const day = daysFromBrowserUrl(pathname, params);
  const pathWhat = parsed.what ?? stripFiltersFromPath(pathname).what;
  const queryWhat = parseWhatParam(params.get("q"));
  const what = [...pathWhat];
  for (const token of queryWhat) {
    if (!what.some((item) => item.toLowerCase() === token.toLowerCase())) {
      what.push(token);
    }
  }
  const qs = isMap
    ? stripLocationParams(params)
    : stripCatalogWhatFromParams(stripLocationParams(params));
  if (isMap) {
    // Map URLs never carry what; the map entry owns it once on the client.
    qs.delete("q");
  }

  let path: string;
  if (isMap) {
    path = whereToMapPath();
  } else if (legacy.type === "nearby") {
    path = appendFiltersToPath(`/${NEARBY_WHERE_SLUG}`, day, what);
  } else {
    path = appendFiltersToPath(`/${legacy.slug}`, day, what);
  }

  return hrefWithQuery(path, qs);
}
