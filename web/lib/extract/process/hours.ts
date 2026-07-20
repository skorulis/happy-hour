/**
 * Ported from `DealScraper/DealScraper/Model/DealHours.swift`.
 *
 * Parses human-written time strings into `DealHours` values where integer
 * minutes are measured from midnight (9AM = 540).
 */

import type { DealHours } from "./types";

const MIN_MINUTES = 420; // 7 AM
const MAX_MINUTES = 1260; // 9 PM
const MORNING_CUTOFF_MINUTE = 10 * 60;
const MINUTES_PER_DAY = 24 * 60;

export function makeBetween(start: number, end: number): DealHours {
  return { kind: "between", start, end: adjustedEndMinute(start, end) };
}

/**
 * When end is earlier on the clock than start and falls before 10 AM, treat it
 * as the next day.
 */
export function adjustedEndMinute(start: number, end: number): number {
  if (end < start && end < MORNING_CUTOFF_MINUTE) {
    return end + MINUTES_PER_DAY;
  }
  return end;
}

export function toMinutes(str: string): number | null {
  const normalized = normalizeTimeComponent(str);
  if (normalized.length === 0) return null;

  switch (normalized) {
    case "noon":
    case "midday":
      return 12 * 60;
    case "midnight":
      return 0;
    default:
      break;
  }

  const match = /^(\d{1,2})(?:[:.](\d{2}))?\s*(am|pm)?$/.exec(normalized);
  const hour = match ? Number.parseInt(match[1]!, 10) : NaN;
  if (!match || !(hour >= 1 && hour <= 12)) {
    return parseCompactMinutes(normalized);
  }

  let minute: number;
  if (match[2] !== undefined) {
    const parsedMinute = Number.parseInt(match[2], 10);
    if (!(parsedMinute >= 0 && parsedMinute < 60)) {
      return null;
    }
    minute = parsedMinute;
  } else {
    minute = 0;
  }

  if (match[3] !== undefined) {
    const isPM = match[3] === "pm";
    return minutesFrom(hour, minute, isPM);
  }

  const amMinutes = minutesFrom(hour, minute, false);
  const pmMinutes = minutesFrom(hour, minute, true);

  const inRange = [amMinutes, pmMinutes].filter(
    (m) => m >= MIN_MINUTES && m <= MAX_MINUTES,
  );
  switch (inRange.length) {
    case 1:
      return inRange[0]!;
    case 2:
      return pmMinutes;
    default:
      return null;
  }
}

/** Parses compact times like `630pm` (6:30 PM) where minutes omit the separator. */
function parseCompactMinutes(normalized: string): number | null {
  const match = /^(\d{3,4})\s*(am|pm)$/.exec(normalized);
  if (!match) return null;

  const digits = match[1]!;
  const minute = Number.parseInt(digits.slice(-2), 10);
  const hour = Number.parseInt(digits.slice(0, -2), 10);
  if (!(hour >= 1 && hour <= 12) || !(minute >= 0 && minute < 60)) {
    return null;
  }

  return minutesFrom(hour, minute, match[2] === "pm");
}

function minutesFrom(hour: number, minute: number, isPM: boolean): number {
  let adjustedHour = hour % 12;
  if (isPM) {
    adjustedHour += 12;
  }
  return adjustedHour * 60 + minute;
}

/** Swift `DealHours.parse` / `fromString`. */
export function parseDealHours(str: string): DealHours | null {
  let normalized = normalizeTimeComponent(str.trim().replace(/\u2013/g, "-"));
  if (normalized.length === 0) return null;

  const lowercased = normalized.toLowerCase();
  if (lowercased.startsWith("available from ")) {
    normalized = normalized.slice("available from ".length).trim();
  } else if (lowercased.startsWith("available ")) {
    normalized = normalized.slice("available ".length).trim();
  } else if (lowercased.startsWith("from ")) {
    normalized = normalized.slice(5).trim();
  }
  if (normalized.length === 0) return null;

  if (
    normalized === "all day" ||
    normalized === "all-day" ||
    normalized === "allday"
  ) {
    return { kind: "allDay" };
  }

  const rangeSeparators = [" - ", "-", " to "];
  for (const separator of rangeSeparators) {
    const parts = normalized
      .split(separator)
      .map((p) => p.trim())
      .filter((p) => p.length > 0);
    if (parts.length === 2) {
      const start = toMinutes(parts[0]!);
      const end = toMinutes(parts[1]!);
      if (start !== null && end !== null) {
        return makeBetween(start, end);
      }
    }
  }

  const minutes = toMinutes(normalized);
  if (minutes === null) return null;
  return { kind: "from", minutes };
}

function normalizeTimeComponent(str: string): string {
  let normalized = str.trim().toLowerCase();
  // Strip trailing punctuation and symbols (Swift `isPunctuation || isSymbol`).
  while (normalized.length > 0 && /[\p{P}\p{S}]$/u.test(normalized)) {
    normalized = normalized.slice(0, -1);
  }
  return normalized;
}
