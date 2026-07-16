import type { DealScheduleInput } from "./sync-deals";

export type OpeningInterval = {
  startMinute: number;
  endMinute: number;
};

/** Calendar weekday → open intervals (1 = Sunday … 7 = Saturday). */
export type VenueOpeningHours = Map<number, OpeningInterval[]>;

type GooglePeriodPoint = {
  day?: number;
  hour?: number;
  minute?: number;
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function pointToMinute(point: GooglePeriodPoint): number | null {
  if (
    typeof point.hour !== "number" ||
    !Number.isFinite(point.hour) ||
    point.hour < 0 ||
    point.hour > 23
  ) {
    return null;
  }

  const minute =
    typeof point.minute === "number" && Number.isFinite(point.minute)
      ? point.minute
      : 0;

  if (minute < 0 || minute > 59) {
    return null;
  }

  return point.hour * 60 + minute;
}

/** Google Places day 0 = Sunday … 6 = Saturday → Calendar weekday 1–7. */
function googleDayToCalendarWeekday(googleDay: number): number | null {
  if (!Number.isInteger(googleDay) || googleDay < 0 || googleDay > 6) {
    return null;
  }
  return googleDay + 1;
}

function daysBetween(openDay: number, closeDay: number): number {
  return (closeDay - openDay + 7) % 7;
}

/**
 * Parse Google Places `regularOpeningHours.periods` from venue JSON.
 * Returns null when periods are missing or unusable (caller leaves schedules as-is).
 */
export function parseVenueOpeningHours(
  venueJson: unknown,
): VenueOpeningHours | null {
  if (!isRecord(venueJson)) {
    return null;
  }

  const openingHours = venueJson.regularOpeningHours;
  if (!isRecord(openingHours)) {
    return null;
  }

  const periods = openingHours.periods;
  if (!Array.isArray(periods) || periods.length === 0) {
    return null;
  }

  const result: VenueOpeningHours = new Map();
  let parsedAny = false;

  for (const period of periods) {
    if (!isRecord(period)) {
      continue;
    }

    const open = period.open as GooglePeriodPoint | undefined;
    if (!isRecord(open) || typeof open.day !== "number") {
      continue;
    }

    const dayOfWeek = googleDayToCalendarWeekday(open.day);
    const startMinute = pointToMinute(open);
    if (dayOfWeek === null || startMinute === null) {
      continue;
    }

    const close = period.close as GooglePeriodPoint | undefined;
    let endMinute: number;

    if (!isRecord(close)) {
      // Open with no close → open 24h that day.
      endMinute = 1_440;
    } else {
      if (typeof close.day !== "number") {
        continue;
      }
      const closeMinute = pointToMinute(close);
      if (closeMinute === null) {
        continue;
      }

      const dayDelta = daysBetween(open.day, close.day);
      endMinute = dayDelta * 1_440 + closeMinute;

      // Same-day close at or before open is invalid; skip.
      if (endMinute <= startMinute) {
        continue;
      }
    }

    const intervals = result.get(dayOfWeek) ?? [];
    intervals.push({ startMinute, endMinute });
    result.set(dayOfWeek, intervals);
    parsedAny = true;
  }

  if (!parsedAny) {
    return null;
  }

  for (const intervals of result.values()) {
    intervals.sort((a, b) => a.startMinute - b.startMinute);
  }

  return result;
}

function intersectIntervals(
  deal: OpeningInterval,
  venue: OpeningInterval,
): OpeningInterval | null {
  const startMinute = Math.max(deal.startMinute, venue.startMinute);
  const endMinute = Math.min(deal.endMinute, venue.endMinute);
  if (endMinute <= startMinute) {
    return null;
  }
  return { startMinute, endMinute };
}

/**
 * Restrict deal schedules to venue opening hours.
 * Days with no overlap are dropped. If openingHours is null, schedules are unchanged.
 */
export function clampSchedulesToOpeningHours(
  schedules: DealScheduleInput[],
  openingHours: VenueOpeningHours | null,
): DealScheduleInput[] {
  if (openingHours === null) {
    return schedules;
  }

  const clamped: DealScheduleInput[] = [];

  for (const schedule of schedules) {
    const venueIntervals = openingHours.get(schedule.dayOfWeek);
    if (!venueIntervals || venueIntervals.length === 0) {
      continue;
    }

    const dealInterval: OpeningInterval = {
      startMinute: schedule.startMinute,
      endMinute: schedule.endMinute,
    };

    for (const venueInterval of venueIntervals) {
      const intersection = intersectIntervals(dealInterval, venueInterval);
      if (intersection) {
        clamped.push({
          dayOfWeek: schedule.dayOfWeek,
          startMinute: intersection.startMinute,
          endMinute: intersection.endMinute,
        });
      }
    }
  }

  return clamped;
}
