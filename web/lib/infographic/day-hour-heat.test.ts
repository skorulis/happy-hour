import { describe, expect, it } from "vitest";
import {
  buildDayHourHeatGrid,
  dealMatchesHappyHour,
  hoursCoveredOnScheduleDay,
  pickPeakDayHour,
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

describe("dealMatchesHappyHour", () => {
  it("matches happy hour titles and synonyms", () => {
    expect(dealMatchesHappyHour({ title: "Happy Hour", details: null, conditions: null })).toBe(
      true,
    );
    expect(
      dealMatchesHappyHour({
        title: "Golden Hour specials",
        details: null,
        conditions: null,
      }),
    ).toBe(true);
  });

  it("ignores drink-only deals", () => {
    expect(
      dealMatchesHappyHour({
        title: "$8 schooners",
        details: "Beer on tap",
        conditions: null,
      }),
    ).toBe(false);
  });
});

describe("hoursCoveredOnScheduleDay", () => {
  it("covers each hour in a window", () => {
    expect(hoursCoveredOnScheduleDay(16 * 60, 18 * 60)).toEqual([16, 17]);
  });

  it("returns empty for all-day schedules", () => {
    expect(hoursCoveredOnScheduleDay(0, 1440)).toEqual([]);
  });

  it("stops at midnight for overnight ends", () => {
    expect(hoursCoveredOnScheduleDay(22 * 60, 26 * 60)).toEqual([22, 23]);
  });
});

describe("tallyHappyHourDayHourCounts", () => {
  it("counts only happy-hour deals inside the noon→11pm window", () => {
    const counts = tallyHappyHourDayHourCounts([
      schedule({
        dealId: 1,
        title: "Happy Hour",
        dayOfWeek: 6,
        startMinute: 16 * 60,
        endMinute: 18 * 60,
      }),
      schedule({
        dealId: 1,
        title: "Happy Hour",
        dayOfWeek: 5,
        startMinute: 17 * 60,
        endMinute: 19 * 60,
      }),
      schedule({
        dealId: 2,
        title: "$6 beer",
        dayOfWeek: 6,
        startMinute: 16 * 60,
        endMinute: 20 * 60,
      }),
      schedule({
        dealId: 3,
        title: "Happy Hour brunch",
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

  it("returns empty when no happy hour deals match", () => {
    expect(
      tallyHappyHourDayHourCounts([
        schedule({
          dealId: 1,
          title: "Steak night",
          dayOfWeek: 4,
          startMinute: 17 * 60,
          endMinute: 21 * 60,
        }),
      ]),
    ).toEqual([]);
  });
});

describe("pickPeakDayHour / buildDayHourHeatGrid", () => {
  it("picks the densest cell and marks it as peak", () => {
    const counts = [
      { dayOfWeek: 5, hour: 17, count: 4 },
      { dayOfWeek: 6, hour: 17, count: 9 },
      { dayOfWeek: 6, hour: 18, count: 3 },
    ];
    expect(pickPeakDayHour(counts)).toEqual({
      dayOfWeek: 6,
      hour: 17,
      count: 9,
    });

    const grid = buildDayHourHeatGrid(counts);
    expect(grid.total).toBe(16);
    expect(grid.peak).toEqual({ dayOfWeek: 6, hour: 17, count: 9 });
    expect(grid.cells).toHaveLength(7 * 12);
    const peakCell = grid.cells.find(
      (cell) => cell.dayOfWeek === 6 && cell.hour === 17,
    );
    expect(peakCell?.isPeak).toBe(true);
    expect(peakCell?.intensity).toBe(1);
  });
});
