/**
 * Ported from `DealScraper/DealScraper/Service/DealMapper.swift`.
 *
 * Turns a raw extracted deal into a cleaned `MappedDeal` (Swift `LegacyDeal`).
 * `mapDeal` is the singular production path; `mapDeals` adds the batch
 * merge/supplement behavior used for test parity.
 */

import { parseAllDealDays, parseDealDay } from "./days";
import type { ExtractedDeal } from "../types";
import { containsExcludedKeyword } from "./filter-keywords";
import {
  comparisonKey,
  formatTitle,
  isPriceLine,
  normalizeConditions,
  normalizeDetails,
  prepareDetails,
  prepareTitle,
} from "./text-normalizer";
import { parseTimes, timesInText } from "./time-parser";
import { trimUntilStable } from "./title-trimmer";
import type { DealHours, MappedDeal } from "./types";
import { hoursKey, uniqueHours } from "./types";

const NEWLINE_SPLIT = /[\n\r\u2028\u2029\u0085\u000b\u000c]/;

export function mapDeal(deal: ExtractedDeal): MappedDeal | null {
  let title = prepareTitle(deal.title);
  let details = prepareDetails(deal.details);

  const dayResolved = resolveDayInTitle(title, details);
  if (dayResolved === null) return null;
  [title, details] = dayResolved;
  [title, details] = withPriceOnlyTitle(title, details);
  [title, details] = withLeadingPriceInTitle(title, details);

  title = trimUntilStable(title);
  title = formatTitle(title);
  if (title.length > 0 && containsExcludedKeyword(title)) {
    return null;
  }
  details = normalizeDetails(details);
  const conditions = normalizeConditions(deal.conditions);
  if (title.length === 0 && details.length === 0 && conditions.length === 0) {
    return null;
  }

  const days = parseAllDealDays(normalizedDayStrings(deal.days));
  const times = parseTimes(deal.times);

  return deduplicated({ title, details, conditions, days, times });
}

export function mapDeals(
  deals: ExtractedDeal[],
  supplementFrom: string[] = [],
): MappedDeal[] {
  const mapped: MappedDeal[] = [];
  for (const deal of deals) {
    const result = mapDeal(deal);
    if (result !== null) {
      mapped.push(supplementTimes(supplementFrom, result));
    }
  }
  return merge(mapped);
}

function normalizedDayStrings(days: string[]): string[] {
  return days.map((day) => day.replace(/\bthrough\b/gi, "to"));
}

function resolveDayInTitle(
  title: string,
  details: string[],
): [string, string[]] | null {
  const trimmedTitle = title.trim();

  if (parseDealDay(trimmedTitle) !== null) {
    const popped = popFirstDetailLine(details);
    if (popped === null) {
      return null;
    }
    return [popped.line, popped.remaining];
  }

  return [trimmedTitle, details];
}

function withPriceOnlyTitle(
  title: string,
  details: string[],
): [string, string[]] {
  if (!isPriceLine(title)) {
    return [title, details];
  }
  const popped = popFirstDetailLine(details);
  if (popped === null) {
    return [title, details];
  }

  let resolvedTitle: string;
  if (comparisonKey(title).includes(comparisonKey(popped.line))) {
    resolvedTitle = title;
  } else {
    resolvedTitle = `${title} ${popped.line}`;
  }

  return [resolvedTitle, popped.remaining];
}

function popFirstDetailLine(
  details: string[],
): { line: string; remaining: string[] } | null {
  for (let index = 0; index < details.length; index++) {
    const lines = details[index]!.split(NEWLINE_SPLIT);
    for (let lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      const trimmed = lines[lineIndex]!.trim();
      if (trimmed.length === 0) continue;

      const remaining = [...details];
      remaining.splice(index, 1);

      const trailingLines = lines
        .slice(lineIndex + 1)
        .join("\n")
        .trim();
      if (trailingLines.length > 0) {
        remaining.splice(index, 0, trailingLines);
      }

      return { line: trimmed, remaining };
    }
  }
  return null;
}

function withLeadingPriceInTitle(
  title: string,
  details: string[],
): [string, string[]] {
  const firstDetail = details[0];
  if (firstDetail === undefined || !isPriceLine(firstDetail)) {
    return [title, details];
  }

  let resolvedTitle: string;
  if (title.length === 0) {
    resolvedTitle = firstDetail;
  } else if (comparisonKey(title).includes(comparisonKey(firstDetail))) {
    resolvedTitle = title;
  } else {
    resolvedTitle = `${title} ${firstDetail}`;
  }

  return [resolvedTitle, details.slice(1)];
}

function deduplicated(deal: MappedDeal): MappedDeal {
  const titleKey = comparisonKey(deal.title);
  const excludeForDetails = new Set<string>();
  if (titleKey.length > 0) {
    excludeForDetails.add(titleKey);
  }

  const details = deduplicatedLines(deal.details, excludeForDetails);
  const detailKeys = details
    .map(comparisonKey)
    .filter((k) => k.length > 0);
  const excludeForConditions = new Set<string>([
    ...excludeForDetails,
    ...detailKeys,
  ]);
  const conditions = deduplicatedLines(deal.conditions, excludeForConditions);

  return {
    title: deal.title,
    details,
    conditions,
    days: deal.days,
    times: deal.times,
  };
}

function deduplicatedLines(lines: string[], excluded: Set<string>): string[] {
  const seen = new Set<string>();
  const result: string[] = [];
  for (const line of lines) {
    const key = comparisonKey(line);
    if (key.length === 0 || excluded.has(key) || seen.has(key)) continue;
    seen.add(key);
    result.push(line);
  }
  return result;
}

function supplementTimes(texts: string[], deal: MappedDeal): MappedDeal {
  if (deal.times.length > 0) return deal;

  const times: DealHours[] = [];
  for (const text of texts) {
    times.push(...timesInText(text));
  }

  const resolvedTimes =
    times.length === 0
      ? [{ kind: "allDay" } as DealHours]
      : uniqueHours(times);

  return {
    title: deal.title,
    details: deal.details,
    conditions: deal.conditions,
    days: deal.days,
    times: resolvedTimes,
  };
}

function merge(deals: MappedDeal[]): MappedDeal[] {
  const merged: MappedDeal[] = [];

  for (const deal of deals) {
    const index = merged.findIndex((existing) => shouldMerge(existing, deal));
    if (index >= 0) {
      const existing = merged[index]!;
      merged[index] = deduplicated({
        title: existing.title.length === 0 ? deal.title : existing.title,
        details: [...existing.details, ...deal.details],
        conditions: [...existing.conditions, ...deal.conditions],
        days: uniqueDays([...existing.days, ...deal.days]),
        times: mergedTimes(existing.times, deal.times),
      });
    } else {
      merged.push(deal);
    }
  }

  return merged;
}

function uniqueDays(days: MappedDeal["days"]): MappedDeal["days"] {
  return Array.from(new Set(days));
}

function shouldMerge(lhs: MappedDeal, rhs: MappedDeal): boolean {
  const rhsText = new Set(dealText(rhs).map((s) => s.toLowerCase()));
  const sharedText = dealText(lhs)
    .map((s) => s.toLowerCase())
    .some((s) => rhsText.has(s));
  if (sharedText) {
    return true;
  }

  // Matching times alone are not enough to merge: distinct deals (e.g. a happy
  // hour and a cocktail special) often run in the same window but describe
  // different products. Only combine deals that share a day and where one side
  // is missing times, so the incomplete deal can inherit the other's window.
  const rhsDays = new Set(rhs.days);
  const sharedDays = lhs.days.some((d) => rhsDays.has(d));
  if (!sharedDays) return false;

  return lhs.times.length === 0 || rhs.times.length === 0;
}

function dealText(deal: MappedDeal): string[] {
  const text: string[] = [];
  if (deal.title.length > 0) {
    text.push(deal.title);
  }
  text.push(...deal.details);
  return text;
}

function mergedTimes(lhs: DealHours[], rhs: DealHours[]): DealHours[] {
  if (lhs.length === 0) return rhs;
  if (rhs.length === 0) return lhs;
  if (hoursArrayEqual(lhs, rhs)) return lhs;
  return uniqueHours([...lhs, ...rhs]);
}

function hoursArrayEqual(lhs: DealHours[], rhs: DealHours[]): boolean {
  if (lhs.length !== rhs.length) return false;
  for (let i = 0; i < lhs.length; i++) {
    if (hoursKey(lhs[i]!) !== hoursKey(rhs[i]!)) return false;
  }
  return true;
}
