import { describe, expect, it } from "vitest";
import { resolveVenueMapIcon } from "./map-icon";

function atLocalTime(
  year: number,
  month: number,
  day: number,
  hours: number,
  minutes = 0,
): Date {
  return new Date(year, month - 1, day, hours, minutes);
}

describe("resolveVenueMapIcon", () => {
  const mondayActiveSchedule = [
    { dayOfWeek: 2, startMinute: 16 * 60, endMinute: 19 * 60 },
  ];
  const mondayInactiveSchedule = [
    { dayOfWeek: 2, startMinute: 20 * 60, endMinute: 22 * 60 },
  ];

  it("prefers icons from active deals over inactive deals", () => {
    const now = atLocalTime(2026, 7, 6, 17, 0);

    expect(
      resolveVenueMapIcon(
        [
          {
            title: "$22 STEAK NIGHT",
            details: null,
            conditions: null,
            schedules: mondayInactiveSchedule,
          },
          {
            title: "$14 Cocktails",
            details: null,
            conditions: null,
            schedules: mondayActiveSchedule,
          },
        ],
        now,
      ),
    ).toBe("Martini");
  });

  it("falls back to inactive deals when active deals have no keyword match", () => {
    const now = atLocalTime(2026, 7, 6, 17, 0);

    expect(
      resolveVenueMapIcon(
        [
          {
            title: "$15 Pizza Night",
            details: null,
            conditions: null,
            schedules: mondayInactiveSchedule,
          },
          {
            title: "$10 specials",
            details: null,
            conditions: null,
            schedules: mondayActiveSchedule,
          },
        ],
        now,
      ),
    ).toBe("Pizza");
  });

  it("matches inactive deals when none are active", () => {
    const now = atLocalTime(2026, 7, 6, 12, 0);

    expect(
      resolveVenueMapIcon(
        [
          {
            title: "$22 STEAK NIGHT",
            details: null,
            conditions: null,
            schedules: mondayActiveSchedule,
          },
        ],
        now,
      ),
    ).toBe("Beef");
  });
});
