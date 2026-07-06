import { describe, expect, it } from "vitest";
import {
  hasAnyDealActiveNow,
  isDealActiveNow,
  isScheduleActiveNow,
  type ScheduleSlice,
} from "./schedule";

function atLocalTime(
  year: number,
  month: number,
  day: number,
  hours: number,
  minutes = 0,
): Date {
  return new Date(year, month - 1, day, hours, minutes);
}

describe("isScheduleActiveNow", () => {
  const weekdayDeal: ScheduleSlice = {
    dayOfWeek: 2, // Monday
    startMinute: 16 * 60, // 4pm
    endMinute: 19 * 60, // 7pm
  };

  it("is active inside a same-day window", () => {
    const now = atLocalTime(2026, 7, 6, 17, 30); // Monday 5:30pm
    expect(isScheduleActiveNow(weekdayDeal, now)).toBe(true);
  });

  it("is inactive outside a same-day window", () => {
    const now = atLocalTime(2026, 7, 6, 15, 0); // Monday 3pm
    expect(isScheduleActiveNow(weekdayDeal, now)).toBe(false);
  });

  it("is active for all-day schedules", () => {
    const allDay: ScheduleSlice = {
      dayOfWeek: 2,
      startMinute: 0,
      endMinute: 1440,
    };
    const now = atLocalTime(2026, 7, 6, 12, 0);
    expect(isScheduleActiveNow(allDay, now)).toBe(true);
  });

  it("is active after midnight for overnight spillover", () => {
    const overnight: ScheduleSlice = {
      dayOfWeek: 6, // Friday
      startMinute: 22 * 60,
      endMinute: 26 * 60, // 2am Saturday
    };
    const now = atLocalTime(2026, 7, 4, 1, 0); // Saturday 1am
    expect(isScheduleActiveNow(overnight, now)).toBe(true);
  });

  it("is inactive before start on overnight start day", () => {
    const overnight: ScheduleSlice = {
      dayOfWeek: 6,
      startMinute: 22 * 60,
      endMinute: 26 * 60,
    };
    const now = atLocalTime(2026, 7, 3, 20, 0); // Friday 8pm
    expect(isScheduleActiveNow(overnight, now)).toBe(false);
  });
});

describe("isDealActiveNow", () => {
  it("returns false for empty schedules", () => {
    expect(isDealActiveNow([])).toBe(false);
  });
});

describe("hasAnyDealActiveNow", () => {
  it("returns true when any deal is active", () => {
    const now = atLocalTime(2026, 7, 6, 17, 0);
    const deals = [
      {
        schedules: [
          { dayOfWeek: 2, startMinute: 16 * 60, endMinute: 19 * 60 },
        ],
      },
      {
        schedules: [
          { dayOfWeek: 2, startMinute: 20 * 60, endMinute: 22 * 60 },
        ],
      },
    ];
    expect(hasAnyDealActiveNow(deals, now)).toBe(true);
  });

  it("returns false when no deals are active", () => {
    const now = atLocalTime(2026, 7, 6, 12, 0);
    const deals = [
      {
        schedules: [
          { dayOfWeek: 2, startMinute: 16 * 60, endMinute: 19 * 60 },
        ],
      },
    ];
    expect(hasAnyDealActiveNow(deals, now)).toBe(false);
  });
});
