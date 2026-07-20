/**
 * Helpers for editing deal schedules in the UI.
 * Ported from Swift `DealScheduleFormatting` end-time / overnight rules.
 */

import { adjustedEndMinute } from "@/lib/extract/process/hours";
import { minutesWithinDay } from "@/lib/search/schedule";

/** Format a minute-of-day value for `<input type="time">` (`HH:MM`). */
export function minuteToTimeInputValue(minute: number): string {
  const normalized = minutesWithinDay(minute);
  const hours = Math.floor(normalized / 60);
  const mins = normalized % 60;
  return `${hours.toString().padStart(2, "0")}:${mins.toString().padStart(2, "0")}`;
}

/** Parse an `<input type="time">` value to minutes from midnight. */
export function timeInputValueToMinutes(value: string): number {
  const [hoursText, minutesText] = value.split(":");
  const hours = Number(hoursText);
  const minutes = Number(minutesText);
  if (
    !Number.isFinite(hours) ||
    !Number.isFinite(minutes) ||
    hours < 0 ||
    hours > 23 ||
    minutes < 0 ||
    minutes > 59
  ) {
    return 0;
  }
  return hours * 60 + minutes;
}

/**
 * Convert a time-input end value to stored end minutes.
 * Midnight (00:00) means end of day (24:00 / 1440).
 */
export function endMinutesFromTimeInput(value: string): number {
  const minutes = timeInputValueToMinutes(value);
  return minutes === 0 ? 1440 : minutes;
}

/**
 * Normalize an end minute relative to start, applying overnight rules.
 * Matches Swift `DealScheduleFormatting.normalizedEndMinute`.
 */
export function normalizedEndMinute(
  endMinute: number,
  startMinute: number,
): number {
  if (endMinute === 1440) {
    return adjustedEndMinute(startMinute, 0);
  }
  if (endMinute > 1440) {
    return adjustedEndMinute(startMinute, minutesWithinDay(endMinute));
  }
  return adjustedEndMinute(startMinute, endMinute);
}

/** End minutes from a time input, normalized against the schedule start. */
export function endMinutesFromTimeInputRelativeToStart(
  value: string,
  startMinute: number,
): number {
  return normalizedEndMinute(endMinutesFromTimeInput(value), startMinute);
}

export const DEFAULT_SCHEDULE_DAY = 2;
export const DEFAULT_SCHEDULE_START_MINUTE = 960;
export const DEFAULT_SCHEDULE_END_MINUTE = 1080;
