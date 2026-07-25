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
  syncMapEntryDays,
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

  it("moves map q catalog tokens into the list path", () => {
    const entry: MapEntry = {
      listPath: "/abbotsbury-2176/thursday",
      source: { kind: "suburb", slug: "abbotsbury-2176" },
      cameraPending: false,
    };

    expect(
      listHrefFromMapEntry(
        entry,
        new URLSearchParams("q=beer"),
        "/map",
      ),
    ).toBe("/abbotsbury-2176/thursday-beer");
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

describe("syncMapEntryDays", () => {
  it("rewrites the stored list path day while keeping the source and what", () => {
    const storage = memoryStorage();
    writeMapEntry(
      mapEntryFromListPathname("/abbotsbury-2176/monday-beer"),
      storage,
    );

    syncMapEntryDays([5], storage);

    expect(readMapEntry(storage)).toEqual({
      listPath: "/abbotsbury-2176/thursday-beer",
      source: { kind: "suburb", slug: "abbotsbury-2176" },
      cameraPending: true,
    });
  });

  it("clears the day segment when the map day filter is cleared", () => {
    const storage = memoryStorage();
    writeMapEntry(mapEntryFromListPathname("/nearby/monday"), storage);

    syncMapEntryDays([], storage);

    expect(readMapEntry(storage)?.listPath).toBe("/nearby");
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
