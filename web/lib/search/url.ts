import type { SearchFilters } from "@/components/search/SearchBar";
import type { TimeRange } from "@/components/search/DayPicker";
import type { WhereFilter } from "@/components/search/SuburbSelect";

export type SearchViewMode = "list" | "map";

export const DEFAULT_SEARCH_FILTERS: SearchFilters = {
  days: [],
  timeRange: null,
  where: { kind: "anywhere" },
  query: "",
};

export const DEFAULT_VIEW_MODE: SearchViewMode = "list";

export function parseViewMode(params: URLSearchParams): SearchViewMode {
  return params.get("view") === "map" ? "map" : "list";
}

function parseDaysParam(value: string | null): number[] {
  if (value === null || value.trim() === "") {
    return [];
  }

  const days = value
    .split(",")
    .map((part) => Number(part.trim()))
    .filter((day) => Number.isFinite(day) && day >= 1 && day <= 7);

  return days;
}

function parseTimeRange(
  startMinuteParam: string | null,
  endMinuteParam: string | null,
): TimeRange {
  if (
    startMinuteParam === null ||
    startMinuteParam === "" ||
    endMinuteParam === null ||
    endMinuteParam === ""
  ) {
    return null;
  }

  const startMinute = Number(startMinuteParam);
  const endMinute = Number(endMinuteParam);

  if (
    !Number.isFinite(startMinute) ||
    !Number.isFinite(endMinute) ||
    startMinute < 0 ||
    startMinute > 1439 ||
    endMinute < 1 ||
    endMinute > 1440 ||
    endMinute <= startMinute
  ) {
    return null;
  }

  return { startMinute, endMinute };
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

export function filtersToSearchParams(
  filters: SearchFilters,
  query: string,
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
    params.set("startMinute", String(filters.timeRange.startMinute));
    params.set("endMinute", String(filters.timeRange.endMinute));
  }
  if (query.trim()) {
    params.set("q", query.trim());
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
    query: params.get("q") ?? "",
  };
}