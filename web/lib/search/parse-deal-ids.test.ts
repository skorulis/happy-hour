import { describe, expect, it } from "vitest";
import {
  MAX_DEAL_IDS_PARAM,
  parseDealIdsParam,
} from "./parse-deal-ids";

describe("parseDealIdsParam", () => {
  it("returns an empty list for null or blank input", () => {
    expect(parseDealIdsParam(null)).toEqual({ ok: true, ids: [] });
    expect(parseDealIdsParam("")).toEqual({ ok: true, ids: [] });
    expect(parseDealIdsParam("   ")).toEqual({ ok: true, ids: [] });
  });

  it("parses comma-separated positive integers", () => {
    expect(parseDealIdsParam("12,45,99")).toEqual({
      ok: true,
      ids: [12, 45, 99],
    });
    expect(parseDealIdsParam(" 7 , 8 ")).toEqual({ ok: true, ids: [7, 8] });
  });

  it("rejects invalid ids", () => {
    expect(parseDealIdsParam("1,abc")).toEqual({
      ok: false,
      error: "Invalid ids",
    });
    expect(parseDealIdsParam("0")).toEqual({
      ok: false,
      error: "Invalid ids",
    });
    expect(parseDealIdsParam("-3")).toEqual({
      ok: false,
      error: "Invalid ids",
    });
    expect(parseDealIdsParam("1.5")).toEqual({
      ok: false,
      error: "Invalid ids",
    });
    expect(parseDealIdsParam("1,,2")).toEqual({
      ok: false,
      error: "Invalid ids",
    });
  });

  it("rejects lists longer than the max", () => {
    const ids = Array.from({ length: MAX_DEAL_IDS_PARAM + 1 }, (_, index) =>
      String(index + 1),
    ).join(",");

    expect(parseDealIdsParam(ids)).toEqual({
      ok: false,
      error: `Too many ids (max ${MAX_DEAL_IDS_PARAM})`,
    });
  });
});
