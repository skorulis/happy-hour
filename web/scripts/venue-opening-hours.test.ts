import { describe, expect, it } from "vitest";
import {
  clampSchedulesToOpeningHours,
  parseVenueOpeningHours,
} from "./venue-opening-hours";
import type { DealScheduleInput } from "./sync-deals";

describe("parseVenueOpeningHours", () => {
  it("returns null when opening hours are missing", () => {
    expect(parseVenueOpeningHours(null)).toBeNull();
    expect(parseVenueOpeningHours({})).toBeNull();
    expect(
      parseVenueOpeningHours({ regularOpeningHours: { periods: [] } }),
    ).toBeNull();
  });

  it("converts Google day index to calendar weekday", () => {
    // Google day 1 = Monday → calendar weekday 2
    const hours = parseVenueOpeningHours({
      regularOpeningHours: {
        periods: [
          {
            open: { day: 1, hour: 8, minute: 0 },
            close: { day: 1, hour: 18, minute: 0 },
          },
        ],
      },
    });

    expect(hours).not.toBeNull();
    expect(hours!.get(2)).toEqual([{ startMinute: 480, endMinute: 1080 }]);
  });

  it("treats open-only periods as 24h that day", () => {
    const hours = parseVenueOpeningHours({
      regularOpeningHours: {
        periods: [{ open: { day: 0, hour: 0, minute: 0 } }],
      },
    });

    expect(hours!.get(1)).toEqual([{ startMinute: 0, endMinute: 1440 }]);
  });

  it("encodes overnight closes with endMinute > 1440", () => {
    // Friday 10pm – Saturday 2am (Google days 5 → 6)
    const hours = parseVenueOpeningHours({
      regularOpeningHours: {
        periods: [
          {
            open: { day: 5, hour: 22, minute: 0 },
            close: { day: 6, hour: 2, minute: 0 },
          },
        ],
      },
    });

    // Google Friday = 5 → calendar weekday 6
    expect(hours!.get(6)).toEqual([{ startMinute: 1320, endMinute: 1560 }]);
  });
});

describe("clampSchedulesToOpeningHours", () => {
  const mondayOpen8to6 = parseVenueOpeningHours({
    regularOpeningHours: {
      periods: [
        {
          open: { day: 1, hour: 8, minute: 0 },
          close: { day: 1, hour: 18, minute: 0 },
        },
      ],
    },
  });

  it("leaves schedules unchanged when opening hours are null", () => {
    const schedules: DealScheduleInput[] = [
      { dayOfWeek: 2, startMinute: 0, endMinute: 1440 },
    ];
    expect(clampSchedulesToOpeningHours(schedules, null)).toEqual(schedules);
  });

  it("clamps all-day deals to venue opening hours", () => {
    expect(
      clampSchedulesToOpeningHours(
        [{ dayOfWeek: 2, startMinute: 0, endMinute: 1440 }],
        mondayOpen8to6,
      ),
    ).toEqual([{ dayOfWeek: 2, startMinute: 480, endMinute: 1080 }]);
  });

  it("leaves deals already inside opening hours unchanged", () => {
    expect(
      clampSchedulesToOpeningHours(
        [{ dayOfWeek: 2, startMinute: 960, endMinute: 1080 }],
        mondayOpen8to6,
      ),
    ).toEqual([{ dayOfWeek: 2, startMinute: 960, endMinute: 1080 }]);
  });

  it("clamps partial overlaps to the intersection", () => {
    // Deal 6AM–10AM vs venue 8AM–6PM → 8AM–10AM
    expect(
      clampSchedulesToOpeningHours(
        [{ dayOfWeek: 2, startMinute: 360, endMinute: 600 }],
        mondayOpen8to6,
      ),
    ).toEqual([{ dayOfWeek: 2, startMinute: 480, endMinute: 600 }]);
  });

  it("drops days with no overlap", () => {
    // Deal 9PM–11PM vs venue closes 6PM
    expect(
      clampSchedulesToOpeningHours(
        [{ dayOfWeek: 2, startMinute: 1260, endMinute: 1380 }],
        mondayOpen8to6,
      ),
    ).toEqual([]);
  });

  it("drops schedules for days the venue is closed", () => {
    expect(
      clampSchedulesToOpeningHours(
        [{ dayOfWeek: 3, startMinute: 0, endMinute: 1440 }],
        mondayOpen8to6,
      ),
    ).toEqual([]);
  });

  it("intersects overnight deals with overnight venue hours", () => {
    const fridayOvernight = parseVenueOpeningHours({
      regularOpeningHours: {
        periods: [
          {
            open: { day: 5, hour: 18, minute: 0 },
            close: { day: 6, hour: 2, minute: 0 },
          },
        ],
      },
    });

    // Deal Fri 10pm–3am (1320–1620) vs venue 6pm–2am (1080–1560) → 10pm–2am
    expect(
      clampSchedulesToOpeningHours(
        [{ dayOfWeek: 6, startMinute: 1320, endMinute: 1620 }],
        fridayOvernight,
      ),
    ).toEqual([{ dayOfWeek: 6, startMinute: 1320, endMinute: 1560 }]);
  });

  it("emits multiple rows when a deal overlaps multiple venue periods", () => {
    const splitDay = parseVenueOpeningHours({
      regularOpeningHours: {
        periods: [
          {
            open: { day: 1, hour: 11, minute: 0 },
            close: { day: 1, hour: 15, minute: 0 },
          },
          {
            open: { day: 1, hour: 17, minute: 0 },
            close: { day: 1, hour: 22, minute: 0 },
          },
        ],
      },
    });

    expect(
      clampSchedulesToOpeningHours(
        [{ dayOfWeek: 2, startMinute: 0, endMinute: 1440 }],
        splitDay,
      ),
    ).toEqual([
      { dayOfWeek: 2, startMinute: 660, endMinute: 900 },
      { dayOfWeek: 2, startMinute: 1020, endMinute: 1320 },
    ]);
  });
});
