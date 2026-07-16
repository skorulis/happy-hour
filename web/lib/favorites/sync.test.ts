import { describe, expect, it } from "vitest";
import { unionFavoriteDealIds } from "./sync";

describe("unionFavoriteDealIds", () => {
  it("merges local and server ids without duplicates", () => {
    expect(unionFavoriteDealIds([1, 2], [2, 3])).toEqual([1, 2, 3]);
  });

  it("preserves local order then appends new server ids", () => {
    expect(unionFavoriteDealIds([3, 1], [1, 2, 4])).toEqual([3, 1, 2, 4]);
  });

  it("returns local ids when the server list is empty", () => {
    expect(unionFavoriteDealIds([5, 6], [])).toEqual([5, 6]);
  });

  it("returns server ids when the local list is empty", () => {
    expect(unionFavoriteDealIds([], [7, 8])).toEqual([7, 8]);
  });
});
