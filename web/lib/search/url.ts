import type { SearchFilters } from "@/components/search/SearchBar";
import type { TimeRange } from "@/components/search/DayPicker";
import type { WhereFilter } from "@/components/search/SuburbSelect";

export type SearchViewMode = "list" | "map";

export const DEFAULT_SEARCH_FILTERS: SearchFilters = {
  days: [],
  timeRange: null,
  where: { kind: "anywhere" },
  what: [],
};

export const DEFAULT_VIEW_MODE: SearchViewMode = "list";

export function parseViewMode(params: URLSearchParams): SearchViewMode {
  return params.get("view") === "map" ? "map" : "list";
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

function parseWhereFilter(params: URLSearchParams): WhereFilter {
  const suburbIdParam = params.get("suburbId");
  const latParam = params.get("lat");
  const lngParam = params.get("lng");

  if (suburbIdParam !== null && suburbIdParam !== "") {
    const id = Number(suburbIdParam);
    if (Number.isFinite(id)) {
      const name = params.get("suburbName") ?? `#${id}`;
      const postcode = params.get("suburbPostcode");
      return {
        kind: "suburb",
        id,
        suburb: {
          id,
          name,
          postcode: postcode && postcode.length > 0 ? postcode : null,
        },
      };
    }
  }

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
      return { kind: "nearMe", lat, lng };
    }
  }

  return { kind: "anywhere" };
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

export function filtersToSearchParams(
  filters: SearchFilters,
  what: string[],
  viewMode: SearchViewMode = DEFAULT_VIEW_MODE,
): URLSearchParams {
  const params = new URLSearchParams();

  if (filters.days.length > 0) {
    params.set("days", filters.days.join(","));
  }
  if (filters.where.kind === "suburb") {
    params.set("suburbId", String(filters.where.id));
    params.set("suburbName", filters.where.suburb.name);
    if (filters.where.suburb.postcode) {
      params.set("suburbPostcode", filters.where.suburb.postcode);
    }
  } else if (filters.where.kind === "nearMe") {
    params.set("lat", String(filters.where.lat));
    params.set("lng", String(filters.where.lng));
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
  if (viewMode === "map") {
    params.set("view", "map");
  }

  return params;
}

export function searchParamsToFilters(params: URLSearchParams): SearchFilters {
  return {
    days: parseDaysParam(params.get("days")),
    timeRange: parseTimeRange(
      params.get("startMinute"),
      params.get("endMinute"),
    ),
    where: parseWhereFilter(params),
    what: parseWhatParam(params.get("q")),
  };
}

export function filtersToApiSearchParams(
  filters: SearchFilters,
  what: string[],
): URLSearchParams {
  return filtersToSearchParams(filters, what);
}
