import type { SearchFilters } from "@/components/search/SearchBar";
import type { TimeRange } from "@/components/search/DayPicker";
import type { WhereFilter } from "@/components/search/SuburbSelect";
import { boundsToApiParams, type MapBounds } from "@/lib/search/bounds";
import {
  NEARBY_WHERE_SLUG,
  suburbWherePath,
  suburbWhereSlug,
} from "@/lib/search/slugs";

export const DEFAULT_SEARCH_FILTERS: SearchFilters = {
  days: [],
  timeRange: null,
  where: { kind: "anywhere" },
  what: [],
};

export type WherePathKind =
  | { kind: "anywhere"; map: boolean }
  | { kind: "nearby"; map: boolean }
  | { kind: "suburb"; slug: string; map: boolean };

export function stripLocationParams(params: URLSearchParams): URLSearchParams {
  const filtered = new URLSearchParams(params.toString());
  filtered.delete("view");
  filtered.delete("suburbId");
  filtered.delete("suburbName");
  filtered.delete("suburbPostcode");
  filtered.delete("lat");
  filtered.delete("lng");
  return filtered;
}

export function parseWherePath(pathname: string): WherePathKind {
  const segments = pathname.split("/").filter(Boolean);

  if (segments.length === 0) {
    return { kind: "anywhere", map: false };
  }

  if (segments.length === 1 && segments[0] === "map") {
    return { kind: "anywhere", map: true };
  }

  if (segments[0] === NEARBY_WHERE_SLUG) {
    return {
      kind: "nearby",
      map: segments[1] === "map",
    };
  }

  if (segments.length === 1) {
    return { kind: "suburb", slug: segments[0]!, map: false };
  }

  if (segments.length === 2 && segments[1] === "map") {
    return { kind: "suburb", slug: segments[0]!, map: true };
  }

  return { kind: "anywhere", map: false };
}

export function whereToListPath(where: WhereFilter): string {
  if (where.kind === "suburb") {
    return suburbWherePath(where.suburb.name, where.suburb.postcode);
  }
  if (where.kind === "nearMe") {
    return `/${NEARBY_WHERE_SLUG}`;
  }
  return "/";
}

/** Map is always `/map` — it uses viewport bounds, not the where filter. */
export function whereToMapPath(): string {
  return "/map";
}

export function filtersToBrowserPath(
  filters: SearchFilters,
  pathname: string,
): string {
  const parsed = parseWherePath(pathname);
  return parsed.map ? whereToMapPath() : whereToListPath(filters.where);
}

export function pathnameToMapHref(
  _pathname: string,
  params: URLSearchParams,
): string {
  const qs = stripLocationParams(params).toString();
  return qs ? `/map?${qs}` : "/map";
}

export function pathnameToListHref(
  pathname: string,
  params: URLSearchParams,
): string {
  const parsed = parseWherePath(pathname);
  const qs = stripLocationParams(params).toString();
  let path: string;
  if (parsed.kind === "nearby") {
    path = `/${NEARBY_WHERE_SLUG}`;
  } else if (parsed.kind === "suburb") {
    path = `/${parsed.slug}`;
  } else {
    path = "/";
  }
  return qs ? `${path}?${qs}` : path;
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

/** Append `?days=` only when a day filter is selected; empty means any day. */
export function appendDaysParam(path: string, days: number[]): string {
  if (days.length === 0) {
    return path;
  }
  return `${path}?days=${days.join(",")}`;
}

export function initialVenueDay(days: number[]): number | null {
  return days.length === 1 ? days[0]! : null;
}

function parseTimeRange(
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

/** Browser URL query params — days, time, and what only. */
export function filtersToBrowserSearchParams(
  filters: SearchFilters,
  what: string[],
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
): SearchFilters {
  return {
    days: parseDaysParam(params.get("days")),
    timeRange: parseTimeRange(
      params.get("startMinute"),
      params.get("endMinute"),
    ),
    where,
    what: parseWhatParam(params.get("q")),
  };
}

/**
 * Filters for the main search page. Empty `days` stays empty in state/URL
 * (any day — no day filter).
 */
export function searchParamsToInitialFilters(
  params: URLSearchParams,
  where: WhereFilter = { kind: "anywhere" },
): SearchFilters {
  return searchParamsToFilters(params, where);
}

/** API query params — includes suburbId or lat/lng for the deals endpoint. */
export function filtersToApiSearchParams(
  filters: SearchFilters,
  what: string[],
): URLSearchParams {
  const params = filtersToBrowserSearchParams(filters, what);

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

  const isMap =
    params.get("view") === "map" ||
    parseWherePath(pathname).map ||
    pathname === "/map";
  const qs = stripLocationParams(params).toString();

  // Map always uses `/map`; list keeps the where path.
  let path: string;
  if (isMap) {
    path = "/map";
  } else if (legacy.type === "nearby") {
    path = `/${NEARBY_WHERE_SLUG}`;
  } else {
    path = `/${legacy.slug}`;
  }

  return qs ? `${path}?${qs}` : path;
}
