import { describe, expect, it } from "vitest";
import {
  buildBeerGlassGeometry,
  normalizeWeekdayPercents,
} from "@/lib/infographic/beer-glass";
import { WEEKDAY_UI_ORDER } from "@/lib/search/schedule";

describe("normalizeWeekdayPercents", () => {
  it("returns zero percents when there are no counts", () => {
    const days = normalizeWeekdayPercents([]);
    expect(days).toHaveLength(7);
    expect(days.every((day) => day.percent === 0 && day.count === 0)).toBe(
      true,
    );
  });

  it("sums to 100 with largest-remainder rounding", () => {
    const days = normalizeWeekdayPercents([
      { dayOfWeek: 2, count: 1 },
      { dayOfWeek: 3, count: 1 },
      { dayOfWeek: 4, count: 1 },
    ]);
    expect(days.reduce((sum, day) => sum + day.percent, 0)).toBe(100);
    expect(days.filter((day) => day.count > 0).every((day) => day.percent > 0))
      .toBe(true);
  });

  it("gives 100% to a single day", () => {
    const days = normalizeWeekdayPercents([{ dayOfWeek: 6, count: 40 }]);
    const friday = days.find((day) => day.dayOfWeek === 6);
    expect(friday?.percent).toBe(100);
    expect(days.filter((day) => day.dayOfWeek !== 6).every((d) => d.percent === 0))
      .toBe(true);
  });

  it("follows Mon→Sun order", () => {
    const days = normalizeWeekdayPercents([{ dayOfWeek: 1, count: 5 }]);
    expect(days.map((day) => day.dayOfWeek)).toEqual([...WEEKDAY_UI_ORDER]);
  });
});

describe("buildBeerGlassGeometry", () => {
  it("builds seven bands for equal day counts", () => {
    const days = normalizeWeekdayPercents(
      WEEKDAY_UI_ORDER.map((dayOfWeek) => ({ dayOfWeek, count: 10 })),
    );
    expect(days.reduce((sum, day) => sum + day.percent, 0)).toBe(100);
    const geometry = buildBeerGlassGeometry(days);
    expect(geometry.segments).toHaveLength(7);
    expect(geometry.legend).toHaveLength(7);
    expect(geometry.legend.every((item) => item.leaderPath !== null)).toBe(
      true,
    );
    expect(geometry.foamPath).not.toBeNull();
    expect(geometry.outlinePath.length).toBeGreaterThan(0);
  });

  it("builds a single full body for one 100% day", () => {
    const days = normalizeWeekdayPercents([{ dayOfWeek: 5, count: 12 }]);
    const geometry = buildBeerGlassGeometry(days);
    expect(geometry.segments).toHaveLength(1);
    expect(geometry.segments[0]!.dayOfWeek).toBe(5);
    expect(geometry.segments[0]!.percent).toBe(100);
    const withLeader = geometry.legend.filter((item) => item.leaderPath);
    expect(withLeader).toHaveLength(1);
    expect(withLeader[0]!.dayOfWeek).toBe(5);
  });

  it("returns no segments when all percents are zero", () => {
    const days = normalizeWeekdayPercents([]);
    const geometry = buildBeerGlassGeometry(days);
    expect(geometry.segments).toEqual([]);
    expect(geometry.foamPath).toBeNull();
    expect(geometry.legend.every((item) => item.leaderPath === null)).toBe(
      true,
    );
  });
});
