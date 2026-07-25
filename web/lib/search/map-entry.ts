import type { MapBounds } from "@/lib/search/bounds";
import {
  appendDayHash,
  daysFromBrowserUrl,
} from "@/lib/search/day-path";
import { parseWherePath, stripLocationParams } from "@/lib/search/url";
import {
  appendFiltersToPath,
  splitWhatForPath,
  stripFiltersFromPath,
} from "@/lib/search/what-path";

export const MAP_ENTRY_STORAGE_KEY = "happy-hour:map-entry";

export type MapEntrySource =
  | { kind: "anywhere" }
  | { kind: "nearby" }
  | { kind: "suburb"; slug: string }
  | { kind: "venue"; lat: number; lng: number };

export type MapEntry = {
  listPath: string;
  source: MapEntrySource;
  /** True until the map has applied the entry as its initial camera. */
  cameraPending: boolean;
  /**
   * Free-text what tokens that cannot live on the list path filter segment.
   * Catalog what stays encoded on `listPath`; this preserves the rest while
   * the map URL itself carries no what (mirrors how day is kept off `/map`).
   */
  queryWhat?: string[];
};

export type VenueMapCameraSeed = {
  listPath: string;
  lat: number;
  lng: number;
};

/** Survives React Strict Mode remounts within the same map visit. */
let seededMapBoundsMemory: MapBounds | null = null;

/** Set while a venue page is mounted so Map → /map can center on that venue. */
let venueMapCameraSeed: VenueMapCameraSeed | null = null;

/** Bumped when the stored map entry changes so nav can refresh list hrefs. */
let mapEntryVersion = 0;
const mapEntryListeners = new Set<() => void>();

function notifyMapEntryListeners(): void {
  mapEntryVersion += 1;
  for (const listener of mapEntryListeners) {
    listener();
  }
}

export function subscribeMapEntry(listener: () => void): () => void {
  mapEntryListeners.add(listener);
  return () => {
    mapEntryListeners.delete(listener);
  };
}

export function getMapEntryVersion(): number {
  return mapEntryVersion;
}

function getSessionStorage(): Storage | null {
  try {
    if (typeof window === "undefined") {
      return null;
    }
    return window.sessionStorage;
  } catch {
    return null;
  }
}

function isFiniteCoordinate(value: unknown): value is number {
  return typeof value === "number" && Number.isFinite(value);
}

function isMapEntrySource(value: unknown): value is MapEntrySource {
  if (!value || typeof value !== "object") {
    return false;
  }

  const source = value as {
    kind?: unknown;
    slug?: unknown;
    lat?: unknown;
    lng?: unknown;
  };
  if (source.kind === "anywhere" || source.kind === "nearby") {
    return true;
  }

  if (
    source.kind === "suburb" &&
    typeof source.slug === "string" &&
    source.slug.length > 0
  ) {
    return true;
  }

  return (
    source.kind === "venue" &&
    isFiniteCoordinate(source.lat) &&
    isFiniteCoordinate(source.lng)
  );
}

function parseMapEntry(raw: string | null): MapEntry | null {
  if (!raw) {
    return null;
  }

  try {
    const parsed: unknown = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") {
      return null;
    }

    const entry = parsed as {
      listPath?: unknown;
      source?: unknown;
      cameraPending?: unknown;
      queryWhat?: unknown;
    };

    if (typeof entry.listPath !== "string" || entry.listPath.length === 0) {
      return null;
    }

    if (!isMapEntrySource(entry.source)) {
      return null;
    }

    const queryWhat = Array.isArray(entry.queryWhat)
      ? entry.queryWhat.filter(
          (token): token is string =>
            typeof token === "string" && token.length > 0,
        )
      : [];

    return {
      listPath: entry.listPath,
      source: entry.source,
      cameraPending: entry.cameraPending === true,
      ...(queryWhat.length > 0 ? { queryWhat } : {}),
    };
  } catch {
    return null;
  }
}

export function setVenueMapCameraSeed(seed: VenueMapCameraSeed): void {
  venueMapCameraSeed = seed;
}

export function clearVenueMapCameraSeed(): void {
  venueMapCameraSeed = null;
}

export function readVenueMapCameraSeed(): VenueMapCameraSeed | null {
  return venueMapCameraSeed;
}

export function mapEntryFromVenue(
  listPath: string,
  lat: number,
  lng: number,
): MapEntry {
  return {
    listPath,
    source: { kind: "venue", lat, lng },
    cameraPending: true,
  };
}

export function mapEntryFromListPathname(
  pathname: string,
  queryWhat: string[] = [],
): MapEntry {
  const venueSeed = venueMapCameraSeed;
  if (venueSeed && venueSeed.listPath === pathname) {
    return mapEntryFromVenue(venueSeed.listPath, venueSeed.lat, venueSeed.lng);
  }

  const parsed = parseWherePath(pathname);
  const day = parsed.day !== undefined ? [parsed.day] : [];
  const what = parsed.what ?? [];
  const freeText = queryWhat.filter((token) => token.trim().length > 0);
  const queryWhatFields = freeText.length > 0 ? { queryWhat: freeText } : {};

  if (parsed.kind === "nearby") {
    return {
      listPath: appendFiltersToPath("/nearby", day, what),
      source: { kind: "nearby" },
      cameraPending: true,
      ...queryWhatFields,
    };
  }

  if (parsed.kind === "suburb") {
    return {
      listPath: appendFiltersToPath(`/${parsed.slug}`, day, what),
      source: { kind: "suburb", slug: parsed.slug },
      cameraPending: true,
      ...queryWhatFields,
    };
  }

  return {
    listPath: appendFiltersToPath("/", day, what),
    source: { kind: "anywhere" },
    cameraPending: true,
    ...queryWhatFields,
  };
}

function baseListPath(path: string): string {
  return stripFiltersFromPath(path).base;
}

/**
 * Days carried onto the map: prefer a legacy `/map-{day}` path, otherwise the
 * day stored on the map-entry list path (map URLs themselves omit the day).
 */
export function daysFromMapEntry(
  entry: MapEntry | null,
  mapPathname?: string,
  params?: URLSearchParams,
): number[] {
  if (mapPathname) {
    const fromMapPath = daysFromBrowserUrl(mapPathname, params);
    if (fromMapPath.length > 0) {
      return fromMapPath;
    }
  }
  if (entry?.listPath) {
    const fromEntry = daysFromBrowserUrl(entry.listPath, params);
    if (fromEntry.length > 0) {
      return fromEntry;
    }
  }
  if (params) {
    return daysFromBrowserUrl("/", params);
  }
  return [];
}

/**
 * What tokens carried by the map entry: catalog tokens encoded on the stored
 * `listPath` plus any free-text tokens kept on the entry. Mirrors how the day
 * is read back from the entry while the map URL itself stays bare.
 */
export function whatFromMapEntry(entry: MapEntry | null): string[] {
  if (!entry) {
    return [];
  }

  const what = [...stripFiltersFromPath(entry.listPath).what];
  for (const token of entry.queryWhat ?? []) {
    if (!what.some((item) => item.toLowerCase() === token.toLowerCase())) {
      what.push(token);
    }
  }
  return what;
}

function hrefWithQueryAndHash(path: string, qs: string): string {
  if (!qs) {
    return path;
  }
  // Hash must come after query if both exist; appendDayHash already places hash last.
  const hashIndex = path.indexOf("#");
  if (hashIndex >= 0) {
    return `${path.slice(0, hashIndex)}?${qs}${path.slice(hashIndex)}`;
  }
  return `${path}?${qs}`;
}

export function listHrefFromMapEntry(
  entry: MapEntry | null,
  params: URLSearchParams,
  mapPathname?: string,
): string {
  const stored = entry?.listPath ?? "/";
  const day = daysFromMapEntry(entry, mapPathname, params);
  const base = baseListPath(stored);

  if (entry?.source.kind === "venue") {
    return hrefWithQueryAndHash(
      appendDayHash(base, day),
      stripLocationParams(params).toString(),
    );
  }

  // What is owned by the map entry (the map URL never carries it), so ignore
  // any stale `q` on the map URL and rebuild it from the entry instead.
  const what = whatFromMapEntry(entry);
  const path = appendFiltersToPath(base, day, what);
  const cleaned = stripLocationParams(params);
  cleaned.delete("q");
  const { queryTokens } = splitWhatForPath(what);
  if (queryTokens.length > 0) {
    cleaned.set("q", queryTokens.join(","));
  }
  return hrefWithQueryAndHash(path, cleaned.toString());
}

function queryWhatEqual(a: string[], b: string[]): boolean {
  return a.length === b.length && a.every((token, index) => token === b[index]);
}

/**
 * Keep the stored list path's day and catalog what in sync while the map URL
 * stays `/map`, preserving free-text what on the entry. Mirrors day handling.
 */
export function syncMapEntryFilters(
  days: number[],
  what: string[],
  storage: Pick<Storage, "getItem" | "setItem"> | null = getSessionStorage(),
): void {
  if (!storage) {
    return;
  }

  const entry = readMapEntry(storage);
  if (!entry) {
    return;
  }

  const stripped = stripFiltersFromPath(entry.listPath);
  const nextListPath = appendFiltersToPath(stripped.base, days, what);
  const { queryTokens } = splitWhatForPath(what);
  const currentQueryWhat = entry.queryWhat ?? [];
  if (
    nextListPath === entry.listPath &&
    queryWhatEqual(currentQueryWhat, queryTokens)
  ) {
    return;
  }

  const nextEntry: MapEntry = {
    ...entry,
    listPath: nextListPath,
    ...(queryTokens.length > 0
      ? { queryWhat: queryTokens }
      : { queryWhat: undefined }),
  };
  if (queryTokens.length === 0) {
    delete nextEntry.queryWhat;
  }

  try {
    // Update in place — do not go through writeMapEntry, which clears the
    // in-memory camera seed used for the current map visit.
    storage.setItem(MAP_ENTRY_STORAGE_KEY, JSON.stringify(nextEntry));
    notifyMapEntryListeners();
  } catch {
    // Ignore quota errors and private browsing restrictions.
  }
}

export function readMapEntry(
  storage: Pick<Storage, "getItem"> | null = getSessionStorage(),
): MapEntry | null {
  if (!storage) {
    return null;
  }

  try {
    return parseMapEntry(storage.getItem(MAP_ENTRY_STORAGE_KEY));
  } catch {
    return null;
  }
}

export function writeMapEntry(
  entry: MapEntry,
  storage: Pick<Storage, "setItem"> | null = getSessionStorage(),
): void {
  seededMapBoundsMemory = null;

  if (!storage) {
    return;
  }

  try {
    storage.setItem(MAP_ENTRY_STORAGE_KEY, JSON.stringify(entry));
    notifyMapEntryListeners();
  } catch {
    // Ignore quota errors and private browsing restrictions.
  }
}

export function rememberSeededMapBounds(bounds: MapBounds): void {
  seededMapBoundsMemory = bounds;
}

export function readSeededMapBounds(): MapBounds | null {
  return seededMapBoundsMemory;
}

/** Returns the map entry when its initial camera has not been applied yet. */
export function readPendingMapEntryCamera(
  storage: Pick<Storage, "getItem"> | null = getSessionStorage(),
): MapEntry | null {
  const entry = readMapEntry(storage);
  if (!entry || !entry.cameraPending) {
    return null;
  }
  return entry;
}

/**
 * Clears `cameraPending` after the map has seeded its initial camera, while
 * keeping `listPath` for map → list navigation.
 */
export function markMapEntryCameraApplied(
  storage: Pick<Storage, "getItem" | "setItem"> | null = getSessionStorage(),
): void {
  if (!storage) {
    return;
  }

  const entry = readMapEntry(storage);
  if (!entry || !entry.cameraPending) {
    return;
  }

  writeMapEntry({ ...entry, cameraPending: false }, storage);
}
