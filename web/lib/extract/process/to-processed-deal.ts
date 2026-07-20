/**
 * Ported from
 * `DealScraper/DealScraper/Service/VenueDealPersistenceMapper.swift`.
 *
 * Converts a single raw extracted deal into a persistence-ready `ProcessedDeal`,
 * applying promotion dates, auto-reject heuristics, meal-time adjustments, and
 * schedule expansion. Returns `null` for deals that should be dropped.
 */

import { calendarWeekday, scheduleDays } from "./days";
import type {
  ExtractDealsSource,
  ExtractedDeal,
  ProcessedDeal,
  ProcessedDealSchedule,
} from "../types";
import { mapDeal } from "./map-deal";
import { isNthWeekdayOfMonthMatch } from "./nth-weekday";
import { parsePromotionDates } from "./promotion-dates";
import type { DealHours, MappedDeal } from "./types";

export function toProcessedDeal(
  raw: ExtractedDeal,
  source: ExtractDealsSource,
): ProcessedDeal | null {
  const mapped = mapDeal(raw);
  if (mapped === null) return null;

  const creativeURL: string | null =
    source.type === "image" || source.type === "pdf" ? source.url : null;
  const sourceURL = source.sourceURL ?? source.url;

  const details = joinedNonEmpty(mapped.details);
  const conditions = joinedNonEmpty(mapped.conditions);
  const title = mapped.title;

  if (title.length === 0 && details === null && conditions === null) {
    return null;
  }

  const promotionDates = parsePromotionDates(raw.promotionDates);

  const autoReject =
    isNthWeekdayOfMonthMatch({
      title: raw.title,
      details: [...raw.details, ...mapped.details],
      conditions: [...raw.conditions, ...mapped.conditions],
      days: raw.days,
    }) ||
    hasSameDayPromotionDates(promotionDates.start, promotionDates.end);

  const schedules = buildSchedules(mapped, title, details);
  if (
    schedules.length === 0 &&
    promotionDates.start === null &&
    promotionDates.end === null
  ) {
    return null;
  }

  return {
    title: title.length === 0 ? null : title,
    details,
    conditions,
    creativeURL,
    sourceURL,
    status: autoReject ? "rejected" : "new",
    startDate: promotionDates.start,
    endDate: promotionDates.end,
    schedules,
  };
}

function hasSameDayPromotionDates(
  start: string | null,
  end: string | null,
): boolean {
  if (start === null || end === null) return false;
  return start === end;
}

function joinedNonEmpty(strings: string[]): string | null {
  const joined = strings
    .map((s) => s.trim())
    .filter((s) => s.length > 0)
    .join("\n");
  return joined.length === 0 ? null : joined;
}

function buildSchedules(
  mapped: MappedDeal,
  title: string,
  details: string | null,
): ProcessedDealSchedule[] {
  const days = mapped.days.flatMap(scheduleDays);
  const times: DealHours[] =
    mapped.times.length === 0 ? [{ kind: "allDay" }] : mapped.times;
  if (days.length === 0) return [];

  const adjustment = mealTimeAdjustment(title, details);

  const schedules: ProcessedDealSchedule[] = [];
  for (const day of days) {
    for (const time of times) {
      const range = scheduleRange(time, adjustment);
      schedules.push({
        dayOfWeek: calendarWeekday(day),
        startMinute: range.start,
        endMinute: range.end,
      });
    }
  }
  return schedules;
}

type MealTimeAdjustment = "dinnerStart" | "lunchRange" | null;

function mealTimeAdjustment(
  title: string,
  details: string | null,
): MealTimeAdjustment {
  let combined = title;
  if (details !== null && details.length > 0) {
    combined = combined.length === 0 ? details : `${combined} ${details}`;
  }
  const lowercased = combined.toLowerCase();
  if (lowercased.includes("all day")) {
    return null;
  }

  const hasLunch = lowercased.includes("lunch");
  const hasNightString =
    lowercased.includes("dinner") ||
    lowercased.includes("evening") ||
    lowercased.includes("night");

  if (hasNightString && !hasLunch) {
    return "dinnerStart";
  }
  if (hasLunch && !hasNightString) {
    return "lunchRange";
  }
  return null;
}

function isMidnightToMidnight(start: number, end: number): boolean {
  return start === 0 && (end === 0 || end === 1440);
}

function scheduleRange(
  hours: DealHours,
  adjustment: MealTimeAdjustment,
): { start: number; end: number } {
  let range: { start: number; end: number };
  switch (hours.kind) {
    case "allDay":
      range = { start: 0, end: 1440 };
      break;
    case "from":
      range = { start: hours.minutes, end: 1440 };
      break;
    case "between":
      range = { start: hours.start, end: hours.end };
      break;
  }

  if (adjustment === "dinnerStart" && range.start === 0) {
    range.start = 17 * 60;
  } else if (
    adjustment === "lunchRange" &&
    isMidnightToMidnight(range.start, range.end)
  ) {
    range = { start: 12 * 60, end: 14 * 60 };
  }
  return range;
}
