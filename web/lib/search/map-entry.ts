import type { MapBounds } from "@/lib/search/bounds";
import { parseWherePath, stripLocationParams } from "@/lib/search/url";

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
    };

    if (typeof entry.listPath !== "string" || entry.listPath.length === 0) {
      return null;
    }

    if (!isMapEntrySource(entry.source)) {
      return null;
    }

    return {
      listPath: entry.listPath,
      source: entry.source,
      cameraPending: entry.cameraPending === true,
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

export function mapEntryFromListPathname(pathname: string): MapEntry {
  const venueSeed = venueMapCameraSeed;
  if (venueSeed && venueSeed.listPath === pathname) {
    return mapEntryFromVenue(venueSeed.listPath, venueSeed.lat, venueSeed.lng);
  }

  const parsed = parseWherePath(pathname);

  if (parsed.kind === "nearby") {
    return {
      listPath: "/nearby",
      source: { kind: "nearby" },
      cameraPending: true,
    };
  }

  if (parsed.kind === "suburb") {
    return {
      listPath: `/${parsed.slug}`,
      source: { kind: "suburb", slug: parsed.slug },
      cameraPending: true,
    };
  }

  return {
    listPath: "/",
    source: { kind: "anywhere" },
    cameraPending: true,
  };
}

export function listHrefFromMapEntry(
  entry: MapEntry | null,
  params: URLSearchParams,
): string {
  const path = entry?.listPath ?? "/";
  const qs = stripLocationParams(params).toString();
  return qs ? `${path}?${qs}` : path;
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
