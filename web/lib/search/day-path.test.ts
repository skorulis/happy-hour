import { describe, expect, it } from "vitest";
import {
  appendDayToPath,
  dayNumberToPathSlug,
  daysFromBrowserUrl,
  pathSlugToDayNumber,
  stripDaySuffix,
} from "./day-path";

describe("dayNumberToPathSlug / pathSlugToDayNumber", () => {
  it("round-trips weekday numbers", () => {
    expect(dayNumberToPathSlug(2)).toBe("monday");
    expect(pathSlugToDayNumber("monday")).toBe(2);
    expect(pathSlugToDayNumber("Thursday")).toBe(5);
    expect(dayNumberToPathSlug(9)).toBeNull();
    expect(pathSlugToDayNumber("weekday")).toBeNull();
  });
});

describe("stripDaySuffix", () => {
  it("strips known weekday suffixes", () => {
    expect(stripDaySuffix("nearby-monday")).toEqual({
      base: "nearby",
      day: 2,
    });
    expect(stripDaySuffix("newtown-2042-monday")).toEqual({
      base: "newtown-2042",
      day: 2,
    });
    expect(stripDaySuffix("the-venue-friday")).toEqual({
      base: "the-venue",
      day: 6,
    });
  });

  it("leaves postcodes and unknown suffixes alone", () => {
    expect(stripDaySuffix("abbotsbury-2176")).toEqual({
      base: "abbotsbury-2176",
      day: null,
    });
    expect(stripDaySuffix("area-12")).toEqual({
      base: "area-12",
      day: null,
    });
    expect(stripDaySuffix("friday-2030")).toEqual({
      base: "friday-2030",
      day: null,
    });
  });
});

describe("appendDayToPath", () => {
  it("appends a single day to the last segment", () => {
    expect(appendDayToPath("/nearby", [2])).toBe("/nearby-monday");
    expect(appendDayToPath("/newtown-2042", [2])).toBe("/newtown-2042-monday");
    expect(appendDayToPath("/newtown/the-venue", [2])).toBe(
      "/newtown/the-venue-monday",
    );
    expect(appendDayToPath("/map", [5])).toBe("/map-thursday");
  });

  it("strips an existing day when clearing the filter", () => {
    expect(appendDayToPath("/nearby-monday", [])).toBe("/nearby");
    expect(appendDayToPath("/newtown-2042-monday", [])).toBe("/newtown-2042");
  });

  it("replaces an existing day suffix", () => {
    expect(appendDayToPath("/nearby-monday", [5])).toBe("/nearby-thursday");
  });

  it("preserves query and hash", () => {
    expect(appendDayToPath("/nearby?q=beer", [2])).toBe(
      "/nearby-monday?q=beer",
    );
  });
});

describe("daysFromBrowserUrl", () => {
  it("prefers the path suffix over query params", () => {
    expect(
      daysFromBrowserUrl(
        "/nearby-monday",
        new URLSearchParams("days=5"),
      ),
    ).toEqual([2]);
  });

  it("falls back to a single legacy days query param", () => {
    expect(daysFromBrowserUrl("/nearby", new URLSearchParams("days=5"))).toEqual(
      [5],
    );
  });

  it("ignores multi-day query values", () => {
    expect(
      daysFromBrowserUrl("/nearby", new URLSearchParams("days=5,6")),
    ).toEqual([]);
  });
});
