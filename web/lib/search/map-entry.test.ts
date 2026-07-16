import { describe, expect, it } from "vitest";
import {
  MAP_ENTRY_STORAGE_KEY,
  listHrefFromMapEntry,
  mapEntryFromListPathname,
  markMapEntryCameraApplied,
  readMapEntry,
  readPendingMapEntryCamera,
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

  it("builds a nearby entry from /nearby", () => {
    expect(mapEntryFromListPathname("/nearby")).toEqual({
      listPath: "/nearby",
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
});

describe("listHrefFromMapEntry", () => {
  it("restores the suburb list path with filter params", () => {
    const entry: MapEntry = {
      listPath: "/abbotsbury-2176",
      source: { kind: "suburb", slug: "abbotsbury-2176" },
      cameraPending: false,
    };

    expect(listHrefFromMapEntry(entry, new URLSearchParams("days=5"))).toBe(
      "/abbotsbury-2176?days=5",
    );
  });

  it("falls back to / when no entry is stored", () => {
    expect(listHrefFromMapEntry(null, new URLSearchParams("q=beer"))).toBe(
      "/?q=beer",
    );
  });

  it("strips legacy location params", () => {
    const entry: MapEntry = {
      listPath: "/nearby",
      source: { kind: "nearby" },
      cameraPending: false,
    };
    const params = new URLSearchParams("days=1&lat=-33.8&lng=151.2");

    expect(listHrefFromMapEntry(entry, params)).toBe("/nearby?days=1");
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
