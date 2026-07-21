import { describe, expect, it } from "vitest";
import {
  ALL_WEEKDAYS,
  currentCalendarWeekday,
  DAY_LABELS,
  formatCompactTimeRange,
  formatDaySelectionLabel,
  formatDealDateRange,
  formatDealScheduleLine,
  formatDealTimeBadge,
  formatSuburbDealsMetadataTitle,
  formatSuburbDealsTitle,
  hasAnyDealActiveNow,
  isDealActiveNow,
  isScheduleActiveNow,
  sortDealsActiveFirst,
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

describe("formatDaySelectionLabel", () => {
  it("labels empty selection as Today", () => {
    expect(formatDaySelectionLabel([])).toBe("Today");
  });

  it("labels all weekdays as Any day", () => {
    expect(formatDaySelectionLabel(ALL_WEEKDAYS)).toBe("Any day");
  });

  it("abbreviates one or two selected days", () => {
    expect(formatDaySelectionLabel([5])).toBe("Thu");
    expect(formatDaySelectionLabel([5, 6])).toBe("Thu, Fri");
  });
});

describe("formatSuburbDealsTitle", () => {
  it("prefixes a single selected day", () => {
    expect(formatSuburbDealsTitle("Sydney", [5])).toBe(
      "Thursday Specials in Sydney",
    );
  });

  it("prefixes today when no day is selected", () => {
    const today = DAY_LABELS[currentCalendarWeekday()];
    expect(formatSuburbDealsTitle("Sydney", [])).toBe(
      `${today} Specials in Sydney`,
    );
  });

  it("omits the day for multiple selections", () => {
    expect(formatSuburbDealsTitle("Sydney", [5, 6])).toBe("Specials in Sydney");
  });

  it("includes a single selected product", () => {
    expect(formatSuburbDealsTitle("Sydney", [1], ["happy hour"])).toBe(
      "Sunday Happy Hour Specials in Sydney",
    );
  });

  it("joins two selected products with and", () => {
    expect(
      formatSuburbDealsTitle("Sydney", [1], ["happy hour", "beer"]),
    ).toBe("Sunday Happy Hour and Beer Specials in Sydney");
  });

  it("omits products when more than two are selected", () => {
    expect(
      formatSuburbDealsTitle("Sydney", [1], ["happy hour", "beer", "wine"]),
    ).toBe("Sunday Specials in Sydney");
  });
});

describe("formatSuburbDealsMetadataTitle", () => {
  it("matches the on-page title including products", () => {
    expect(
      formatSuburbDealsMetadataTitle("Sydney", [5], ["happy hour"]),
    ).toBe("Thursday Happy Hour Specials in Sydney");
  });

  it("omits the day when no day is selected (SSR all-days body)", () => {
    expect(formatSuburbDealsMetadataTitle("Sydney", [])).toBe(
      "Specials in Sydney",
    );
  });

  it("omits the day for multiple selections", () => {
    expect(formatSuburbDealsMetadataTitle("Sydney", [5, 6])).toBe(
      "Specials in Sydney",
    );
  });

  it("keeps a single explicit day in the metadata title", () => {
    expect(formatSuburbDealsMetadataTitle("Sydney", [5])).toBe(
      "Thursday Specials in Sydney",
    );
  });
});

describe("formatCompactTimeRange", () => {
  it("shows Until end time when starting at midnight", () => {
    expect(formatCompactTimeRange(0, 18 * 60)).toBe("Until 6pm");
  });

  it("shows a normal range when not starting at midnight", () => {
    expect(formatCompactTimeRange(16 * 60, 19 * 60)).toBe("4-7pm");
  });

  it("shows From start time when ending at midnight", () => {
    expect(formatCompactTimeRange(19 * 60 + 30, 1440)).toBe("From 7:30pm");
  });
});

describe("formatDealTimeBadge", () => {
  it("uses Until format for start-of-day deals", () => {
    expect(
      formatDealTimeBadge([
        { dayOfWeek: 2, startMinute: 0, endMinute: 18 * 60 },
      ]),
    ).toBe("Until 6pm");
  });

  it("uses From format for end-of-day deals", () => {
    expect(
      formatDealTimeBadge([
        { dayOfWeek: 5, startMinute: 19 * 60 + 30, endMinute: 1440 },
      ]),
    ).toBe("From 7:30pm");
  });
});

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

describe("sortDealsActiveFirst", () => {
  const mondayActiveSchedule: ScheduleSlice[] = [
    { dayOfWeek: 2, startMinute: 16 * 60, endMinute: 19 * 60 },
  ];
  const mondayInactiveSchedule: ScheduleSlice[] = [
    { dayOfWeek: 2, startMinute: 20 * 60, endMinute: 22 * 60 },
  ];

  it("places active deals before inactive deals", () => {
    const now = atLocalTime(2026, 7, 6, 17, 0);
    const deals = [
      { id: 1, schedules: mondayInactiveSchedule },
      { id: 2, schedules: mondayActiveSchedule },
      { id: 3, schedules: mondayInactiveSchedule },
    ];

    expect(sortDealsActiveFirst(deals, now).map((deal) => deal.id)).toEqual([
      2, 1, 3,
    ]);
  });

  it("preserves relative order within active and inactive groups", () => {
    const now = atLocalTime(2026, 7, 6, 17, 0);
    const deals = [
      { id: 1, schedules: mondayInactiveSchedule },
      { id: 2, schedules: mondayActiveSchedule },
      { id: 3, schedules: mondayActiveSchedule },
      { id: 4, schedules: mondayInactiveSchedule },
    ];

    expect(sortDealsActiveFirst(deals, now).map((deal) => deal.id)).toEqual([
      2, 3, 1, 4,
    ]);
  });

  it("returns the same order when all deals are active", () => {
    const now = atLocalTime(2026, 7, 6, 17, 0);
    const deals = [
      { id: 1, schedules: mondayActiveSchedule },
      { id: 2, schedules: mondayActiveSchedule },
    ];

    expect(sortDealsActiveFirst(deals, now).map((deal) => deal.id)).toEqual([
      1, 2,
    ]);
  });

  it("returns the same order when no deals are active", () => {
    const now = atLocalTime(2026, 7, 6, 12, 0);
    const deals = [
      { id: 1, schedules: mondayActiveSchedule },
      { id: 2, schedules: mondayInactiveSchedule },
    ];

    expect(sortDealsActiveFirst(deals, now).map((deal) => deal.id)).toEqual([
      1, 2,
    ]);
  });
});

describe("formatDealDateRange", () => {
  it("returns null when no dates are set", () => {
    expect(formatDealDateRange(null, null)).toBeNull();
  });

  it("formats a date range", () => {
    expect(formatDealDateRange("2025-11-14", "2025-12-01")).toBe(
      "14 Nov 2025 – 1 Dec 2025",
    );
  });

  it("formats a single date when start and end match", () => {
    expect(formatDealDateRange("2025-12-25", "2025-12-25")).toBe(
      "25 Dec 2025",
    );
  });

  it("formats until-only ranges", () => {
    expect(formatDealDateRange(null, "2025-12-31")).toBe("Until 31 Dec 2025");
  });

  it("formats from-only ranges", () => {
    expect(formatDealDateRange("2025-11-14", null)).toBe("From 14 Nov 2025");
  });
});

describe("formatDealScheduleLine", () => {
  it("combines day and time into one line", () => {
    expect(
      formatDealScheduleLine([
        { dayOfWeek: 4, startMinute: 16 * 60, endMinute: 19 * 60 },
      ]),
    ).toBe("Wed · 4-7pm");
  });

  it("includes date ranges before schedule details", () => {
    expect(
      formatDealScheduleLine(
        [{ dayOfWeek: 4, startMinute: 16 * 60, endMinute: 19 * 60 }],
        null,
        "2025-12-31",
      ),
    ).toBe("Until 31 Dec 2025 · Wed · 4-7pm");
  });

  it("returns schedule not listed when empty", () => {
    expect(formatDealScheduleLine([])).toBe("Schedule not listed");
  });

  it("shows date-only promotions without recurring schedules", () => {
    expect(formatDealScheduleLine([], "2025-12-25", "2025-12-25")).toBe(
      "25 Dec 2025",
    );
  });
});
