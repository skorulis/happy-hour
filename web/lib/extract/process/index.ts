/**
 * Deal-mapping pipeline: turns raw `ExtractedDeal`s (from the LLM extractor)
 * into persistence-ready `ProcessedDeal`s.
 *
 * Ported from the Swift `DealScraper` app. `processExtractedDeals` is the
 * production entry point; it maps each deal individually (no cross-deal
 * merging).
 */

import type {
  ExtractDealsSource,
  ExtractedDeal,
  ProcessedDeal,
} from "../types";
import { toProcessedDeal } from "./to-processed-deal";

export function processExtractedDeals(
  extracted: ExtractedDeal[],
  source: ExtractDealsSource,
): ProcessedDeal[] {
  return extracted
    .map((deal) => toProcessedDeal(deal, source))
    .filter((d): d is ProcessedDeal => d != null);
}

export { toProcessedDeal } from "./to-processed-deal";
export { mapDeal, mapDeals } from "./map-deal";
export { parseTimes, timesInText } from "./time-parser";
export {
  parseDealDay,
  parseAllDealDays,
  isDayMentioned,
  calendarWeekday,
  scheduleDays,
} from "./days";
export {
  toMinutes,
  parseDealHours,
  makeBetween,
  adjustedEndMinute,
} from "./hours";
export { parsePromotionDates } from "./promotion-dates";
export { isNthWeekdayOfMonthMatch } from "./nth-weekday";
export { containsExcludedKeyword, excludedKeywords } from "./filter-keywords";
export { trimUntilStable, trimOnce } from "./title-trimmer";
export {
  prepareTitle,
  prepareDetails,
  formatTitle,
  normalizeDetails,
  normalizeConditions,
  comparisonKey,
  isPriceLine,
  cleanLine,
} from "./text-normalizer";
export type { DealDay, DealHours, MappedDeal } from "./types";
export { hoursKey, hoursEqual, uniqueHours } from "./types";
