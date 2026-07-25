import { describe, expect, it } from "vitest";
import {
  MAP_ENTRY_STORAGE_KEY,
  clearVenueMapCameraSeed,
  listHrefFromMapEntry,
  mapEntryFromListPathname,
  mapEntryFromVenue,
  markMapEntryCameraApplied,
  readMapEntry,
  readPendingMapEntryCamera,
  setVenueMapCameraSeed,
  syncMapEntryFilters,
  whatFromMapEntry,
  writeMapEntry,
  type MapEntry,
} from "./map-entry";

function memoryStorage(initial: Record<string, string> = {}) {
  const data = { ...initial };
  return {
    getItem(key: string) {
      return Object.prototype.hasOwnProperty.call(data, key) ? data[key]! : null;
    },
    setItem(key: string, value: string) {
      data[key] = value;
    },
    data,
  };
}

describe("mapEntryFromListPathname", () => {
  it("builds a suburb entry from a suburb list path", () => {
    expect(mapEntryFromListPathname("/abbotsbury-2176")).toEqual({
      listPath: "/abbotsbury-2176",
      source: { kind: "suburb", slug: "abbotsbury-2176" },
      cameraPending: true,
    });
  });

  it("keeps the filter segment on the list path and strips it from the source slug", () => {
    expect(mapEntryFromListPathname("/abbotsbury-2176/monday-beer")).toEqual({
      listPath: "/abbotsbury-2176/monday-beer",
      source: { kind: "suburb", slug: "abbotsbury-2176" },
      cameraPending: true,
    });
  });

  it("normalizes legacy hyphenated day suffixes into path segments", () => {
    expect(mapEntryFromListPathname("/abbotsbury-2176-monday")).toEqual({
      listPath: "/abbotsbury-2176/monday",
      source: { kind: "suburb", slug: "abbotsbury-2176" },
      cameraPending: true,
    });
  });

  it("builds a nearby entry from /nearby", () => {
    expect(mapEntryFromListPathname("/nearby")).toEqual({
      listPath: "/nearby",
      source: { kind: "nearby" },
      cameraPending: true,
    });
  });

  it("builds a nearby entry with a day segment", () => {
    expect(mapEntryFromListPathname("/nearby/monday")).toEqual({
      listPath: "/nearby/monday",
      source: { kind: "nearby" },
      cameraPending: true,
    });
  });

  it("builds an anywhere entry from /", () => {
    expect(mapEntryFromListPathname("/")).toEqual({
      listPath: "/",
      source: { kind: "anywhere" },
      cameraPending: true,
    });
  });

  it("builds a venue entry when a matching venue camera seed is set", () => {
    setVenueMapCameraSeed({
      listPath: "/surry-hills/the-local",
      lat: -33.88,
      lng: 151.21,
    });

    expect(mapEntryFromListPathname("/surry-hills/the-local")).toEqual({
      listPath: "/surry-hills/the-local",
      source: { kind: "venue", lat: -33.88, lng: 151.21 },
      cameraPending: true,
    });

    clearVenueMapCameraSeed();
  });

  it("ignores a venue camera seed when the pathname does not match", () => {
    setVenueMapCameraSeed({
      listPath: "/surry-hills/the-local",
      lat: -33.88,
      lng: 151.21,
    });

    expect(mapEntryFromListPathname("/")).toEqual({
      listPath: "/",
      source: { kind: "anywhere" },
      cameraPending: true,
    });

    clearVenueMapCameraSeed();
  });
});

describe("mapEntryFromVenue", () => {
  it("builds a pending venue camera entry", () => {
    expect(mapEntryFromVenue("/surry-hills/the-local", -33.88, 151.21)).toEqual(
      {
        listPath: "/surry-hills/the-local",
        source: { kind: "venue", lat: -33.88, lng: 151.21 },
        cameraPending: true,
      },
    );
  });
});

describe("listHrefFromMapEntry", () => {
  it("restores the suburb list path with the current map day", () => {
    const entry: MapEntry = {
      listPath: "/abbotsbury-2176",
      source: { kind: "suburb", slug: "abbotsbury-2176" },
      cameraPending: false,
    };

    expect(
      listHrefFromMapEntry(entry, new URLSearchParams(), "/map-thursday"),
    ).toBe("/abbotsbury-2176/thursday");
  });

  it("restores the day from the stored list path when map URL has none", () => {
    const entry: MapEntry = {
      listPath: "/abbotsbury-2176/thursday",
      source: { kind: "suburb", slug: "abbotsbury-2176" },
      cameraPending: false,
    };

    expect(listHrefFromMapEntry(entry, new URLSearchParams(), "/map")).toBe(
      "/abbotsbury-2176/thursday",
    );
  });

  it("restores catalog what stored on the entry path, ignoring map q", () => {
    const entry: MapEntry = {
      listPath: "/abbotsbury-2176/thursday-beer",
      source: { kind: "suburb", slug: "abbotsbury-2176" },
      cameraPending: false,
    };

    // The map URL no longer carries what, so a stray `q` must not leak through.
    expect(
      listHrefFromMapEntry(entry, new URLSearchParams("q=wine"), "/map"),
    ).toBe("/abbotsbury-2176/thursday-beer");
  });

  it("restores free-text what from the entry into the list query", () => {
    const entry: MapEntry = {
      listPath: "/abbotsbury-2176/thursday",
      source: { kind: "suburb", slug: "abbotsbury-2176" },
      cameraPending: false,
      queryWhat: ["obscure snack"],
    };

    expect(listHrefFromMapEntry(entry, new URLSearchParams(), "/map")).toBe(
      "/abbotsbury-2176/thursday?q=obscure+snack",
    );
  });

  it("restores the venue path with a day hash", () => {
    const entry: MapEntry = {
      listPath: "/surry-hills/the-local",
      source: { kind: "venue", lat: -33.88, lng: 151.21 },
      cameraPending: false,
    };

    expect(
      listHrefFromMapEntry(entry, new URLSearchParams(), "/map-thursday"),
    ).toBe("/surry-hills/the-local#thursday");
  });

  it("falls back to / when no entry is stored", () => {
    expect(listHrefFromMapEntry(null, new URLSearchParams("q=beer"))).toBe(
      "/",
    );
  });

  it("strips legacy location params and migrates days into the path", () => {
    const entry: MapEntry = {
      listPath: "/nearby",
      source: { kind: "nearby" },
      cameraPending: false,
    };
    const params = new URLSearchParams("days=1&lat=-33.8&lng=151.2");

    expect(listHrefFromMapEntry(entry, params)).toBe("/nearby/sunday");
  });
});

describe("whatFromMapEntry", () => {
  it("returns [] for a missing entry", () => {
    expect(whatFromMapEntry(null)).toEqual([]);
  });

  it("merges catalog what on the path with free-text queryWhat", () => {
    const entry: MapEntry = {
      listPath: "/abbotsbury-2176/thursday-beer",
      source: { kind: "suburb", slug: "abbotsbury-2176" },
      cameraPending: false,
      queryWhat: ["obscure snack"],
    };

    expect(whatFromMapEntry(entry)).toEqual(["beer", "obscure snack"]);
  });
});

describe("syncMapEntryFilters", () => {
  it("rewrites the stored list path day and catalog what while keeping the source", () => {
    const storage = memoryStorage();
    writeMapEntry(
      mapEntryFromListPathname("/abbotsbury-2176/monday-beer"),
      storage,
    );

    syncMapEntryFilters([5], ["cocktails"], storage);

    expect(readMapEntry(storage)).toEqual({
      listPath: "/abbotsbury-2176/thursday-cocktails",
      source: { kind: "suburb", slug: "abbotsbury-2176" },
      cameraPending: true,
    });
  });

  it("stores free-text what on the entry rather than the path", () => {
    const storage = memoryStorage();
    writeMapEntry(mapEntryFromListPathname("/abbotsbury-2176"), storage);

    syncMapEntryFilters([5], ["beer", "obscure snack"], storage);

    expect(readMapEntry(storage)).toEqual({
      listPath: "/abbotsbury-2176/thursday-beer",
      source: { kind: "suburb", slug: "abbotsbury-2176" },
      cameraPending: true,
      queryWhat: ["obscure snack"],
    });
  });

  it("clears the day and what when both filters are cleared", () => {
    const storage = memoryStorage();
    writeMapEntry(mapEntryFromListPathname("/nearby/monday-beer"), storage);

    syncMapEntryFilters([], [], storage);

    expect(readMapEntry(storage)).toEqual({
      listPath: "/nearby",
      source: { kind: "nearby" },
      cameraPending: true,
    });
  });
});

describe("map entry storage", () => {
  it("writes and reads a map entry", () => {
    const storage = memoryStorage();
    const entry = mapEntryFromListPathname("/nearby");

    writeMapEntry(entry, storage);
    expect(readMapEntry(storage)).toEqual(entry);
    expect(storage.data[MAP_ENTRY_STORAGE_KEY]).toBeTruthy();
  });

  it("writes and reads a venue map entry", () => {
    const storage = memoryStorage();
    const entry = mapEntryFromVenue("/surry-hills/the-local", -33.88, 151.21);

    writeMapEntry(entry, storage);
    expect(readMapEntry(storage)).toEqual(entry);
  });

  it("reads pending camera and clears it after apply while keeping listPath", () => {
    const storage = memoryStorage();
    writeMapEntry(mapEntryFromListPathname("/abbotsbury-2176"), storage);

    expect(readPendingMapEntryCamera(storage)).toEqual({
      listPath: "/abbotsbury-2176",
      source: { kind: "suburb", slug: "abbotsbury-2176" },
      cameraPending: true,
    });

    markMapEntryCameraApplied(storage);

    expect(readMapEntry(storage)).toEqual({
      listPath: "/abbotsbury-2176",
      source: { kind: "suburb", slug: "abbotsbury-2176" },
      cameraPending: false,
    });
    expect(readPendingMapEntryCamera(storage)).toBe(null);
  });

  it("returns null for malformed storage values", () => {
    const storage = memoryStorage({
      [MAP_ENTRY_STORAGE_KEY]: "{not-json",
    });
    expect(readMapEntry(storage)).toBe(null);
  });
});
