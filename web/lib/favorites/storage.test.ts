import { describe, expect, it, vi } from "vitest";
import {
  FAVORITES_STORAGE_KEY,
  readFavoriteDealIds,
  toggleFavoriteDealId,
  writeFavoriteDealIds,
} from "./storage";

function createMemoryStorage(initial: Record<string, string> = {}) {
  const store = new Map(Object.entries(initial));

  return {
    getItem: vi.fn((key: string) => store.get(key) ?? null),
    setItem: vi.fn((key: string, value: string) => {
      store.set(key, value);
    }),
  };
}

describe("readFavoriteDealIds", () => {
  it("returns an empty array when nothing is stored", () => {
    const storage = createMemoryStorage();
    expect(readFavoriteDealIds(storage)).toEqual([]);
  });

  it("parses a stored array of deal ids", () => {
    const storage = createMemoryStorage({
      [FAVORITES_STORAGE_KEY]: "[12, 45, 99]",
    });

    expect(readFavoriteDealIds(storage)).toEqual([12, 45, 99]);
  });

  it("filters invalid entries and falls back for malformed json", () => {
    const invalidEntries = createMemoryStorage({
      [FAVORITES_STORAGE_KEY]: '[1, "2", 3.5, -4, 0, null]',
    });
    const malformed = createMemoryStorage({
      [FAVORITES_STORAGE_KEY]: "not-json",
    });

    expect(readFavoriteDealIds(invalidEntries)).toEqual([1]);
    expect(readFavoriteDealIds(malformed)).toEqual([]);
  });

  it("returns an empty array when storage throws", () => {
    const storage = {
      getItem: vi.fn(() => {
        throw new Error("blocked");
      }),
    };

    expect(readFavoriteDealIds(storage)).toEqual([]);
  });
});

describe("writeFavoriteDealIds", () => {
  it("persists ids as json", () => {
    const storage = createMemoryStorage();

    writeFavoriteDealIds([7, 8], storage);

    expect(storage.setItem).toHaveBeenCalledWith(
      FAVORITES_STORAGE_KEY,
      "[7,8]",
    );
  });

  it("ignores storage write failures", () => {
    const storage = {
      setItem: vi.fn(() => {
        throw new Error("quota exceeded");
      }),
    };

    expect(() => writeFavoriteDealIds([1], storage)).not.toThrow();
  });
});

describe("toggleFavoriteDealId", () => {
  it("adds a deal id when it is not favourited", () => {
    expect(toggleFavoriteDealId([1, 2], 3)).toEqual([1, 2, 3]);
  });

  it("removes a deal id when it is already favourited", () => {
    expect(toggleFavoriteDealId([1, 2, 3], 2)).toEqual([1, 3]);
  });
});
