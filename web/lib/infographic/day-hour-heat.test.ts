import { describe, expect, it } from "vitest";
import {
  buildDayHourHeatGrid,
  DAY_HOUR_HEAT_COLORS,
  DAY_HOUR_HEAT_EMPTY_COLOR,
  happyHourHeatCellHref,
  hoursCoveredOnScheduleDay,
  tallyHappyHourDayHourCounts,
} from "@/lib/infographic/day-hour-heat";
import type { RegionDealScheduleMatchRow } from "@/lib/search/queries";

function schedule(
  overrides: Partial<RegionDealScheduleMatchRow> &
    Pick<RegionDealScheduleMatchRow, "dealId" | "dayOfWeek" | "startMinute" | "endMinute">,
): RegionDealScheduleMatchRow {
  return {
    title: "Happy Hour",
    details: null,
    conditions: null,
    ...overrides,
  };
}

describe("hoursCoveredOnScheduleDay", () => {
  it("covers each hour in a window", () => {
    expect(hoursCoveredOnScheduleDay(16 * 60, 18 * 60)).toEqual([16, 17]);
  });

  it("excludes the end hour when the window ends on the hour", () => {
    expect(hoursCoveredOnScheduleDay(20 * 60, 23 * 60)).toEqual([20, 21, 22]);
  });

  it("only counts hours active at the top of the hour", () => {
    // 10:30pm–11:30pm: active at 11:00, not at 10:00
    expect(hoursCoveredOnScheduleDay(22 * 60 + 30, 23 * 60 + 30)).toEqual([23]);
  });

  it("returns empty for all-day schedules", () => {
    expect(hoursCoveredOnScheduleDay(0, 1440)).toEqual([]);
  });

  it("stops at midnight for overnight ends", () => {
    expect(hoursCoveredOnScheduleDay(22 * 60, 26 * 60)).toEqual([22, 23]);
  });
});

describe("tallyHappyHourDayHourCounts", () => {
  it("counts schedule rows inside the noon→11pm window", () => {
    const counts = tallyHappyHourDayHourCounts([
      schedule({
        dealId: 1,
        dayOfWeek: 6,
        startMinute: 16 * 60,
        endMinute: 18 * 60,
      }),
      schedule({
        dealId: 1,
        dayOfWeek: 5,
        startMinute: 17 * 60,
        endMinute: 19 * 60,
      }),
      schedule({
        dealId: 3,
        dayOfWeek: 7,
        startMinute: 9 * 60,
        endMinute: 11 * 60,
      }),
    ]);

    expect(counts).toEqual(
      expect.arrayContaining([
        { dayOfWeek: 5, hour: 17, count: 1 },
        { dayOfWeek: 5, hour: 18, count: 1 },
        { dayOfWeek: 6, hour: 16, count: 1 },
        { dayOfWeek: 6, hour: 17, count: 1 },
      ]),
    );
    expect(counts.some((cell) => cell.dayOfWeek === 7)).toBe(false);
    expect(counts.some((cell) => cell.hour < 12)).toBe(false);
  });

  it("returns empty when there are no schedule rows", () => {
    expect(tallyHappyHourDayHourCounts([])).toEqual([]);
  });

  it("counts hours while the schedule is on, not only the start hour", () => {
    const counts = tallyHappyHourDayHourCounts([
      schedule({
        dealId: 1,
        dayOfWeek: 4,
        startMinute: 17 * 60,
        endMinute: 21 * 60 + 30,
      }),
      schedule({
        dealId: 2,
        dayOfWeek: 4,
        startMinute: 21 * 60,
        endMinute: 22 * 60,
      }),
    ]);

    expect(counts.find((cell) => cell.dayOfWeek === 4 && cell.hour === 21)).toEqual(
      { dayOfWeek: 4, hour: 21, count: 2 },
    );
    expect(counts.find((cell) => cell.dayOfWeek === 4 && cell.hour === 17)).toEqual(
      { dayOfWeek: 4, hour: 17, count: 1 },
    );
  });
});

describe("pickPeakDayHour / buildDayHourHeatGrid", () => {
  it("picks the densest cell and marks it as peak", () => {
    const grid = buildDayHourHeatGrid([
      { dayOfWeek: 2, hour: 16, count: 2 },
      { dayOfWeek: 5, hour: 17, count: 5 },
      { dayOfWeek: 5, hour: 18, count: 1 },
    ]);

    expect(grid.peak).toEqual({ dayOfWeek: 5, hour: 17, count: 5 });
    expect(grid.total).toBe(8);
    const peakCell = grid.cells.find(
      (cell) => cell.dayOfWeek === 5 && cell.hour === 17,
    );
    expect(peakCell?.isPeak).toBe(true);
    expect(peakCell?.color).toBe(DAY_HOUR_HEAT_COLORS[DAY_HOUR_HEAT_COLORS.length - 1]);
  });

  it("lifts mid values above a linear grey floor", () => {
    const grid = buildDayHourHeatGrid([
      { dayOfWeek: 2, hour: 16, count: 1 },
      { dayOfWeek: 5, hour: 17, count: 4 },
    ]);
    const mid = grid.cells.find((cell) => cell.dayOfWeek === 2 && cell.hour === 16);
    expect(mid?.intensity).toBeCloseTo(0.5);
    expect(mid?.color).not.toBe(DAY_HOUR_HEAT_EMPTY_COLOR);
  });

  it("marks every tied max cell as a peak", () => {
    const grid = buildDayHourHeatGrid([
      { dayOfWeek: 2, hour: 16, count: 3 },
      { dayOfWeek: 5, hour: 17, count: 3 },
    ]);
    expect(grid.cells.filter((cell) => cell.isPeak)).toHaveLength(2);
  });
});

describe("happyHourHeatCellHref", () => {
  it("builds day + happy hour path with point-in-time minutes", () => {
    expect(happyHourHeatCellHref("/sydney", 2, 22)).toBe(
      "/sydney/monday-happyhour?startMinute=1320&endMinute=1320",
    );
    expect(happyHourHeatCellHref("/sydney", 5, 17)).toBe(
      "/sydney/thursday-happyhour?startMinute=1020&endMinute=1020",
    );
  });

  it("preserves suburb where paths that include a postcode", () => {
    expect(happyHourHeatCellHref("/surry-hills-2010", 5, 17)).toBe(
      "/surry-hills-2010/thursday-happyhour?startMinute=1020&endMinute=1020",
    );
  });
});
