/**
 * Ported from `DealScraper/DealScraper/Service/PromotionDateParser.swift`.
 *
 * Parses promotion date strings into a start/end calendar-date range. Dates are
 * returned as local `yyyy-MM-dd` strings (never `Date` objects) to avoid UTC
 * shifting. Month names are matched using en-AU (English) names.
 */

type DateRange = { start: string | null; end: string | null };

const MONTHS: Record<string, number> = {
  january: 1,
  february: 2,
  march: 3,
  april: 4,
  may: 5,
  june: 6,
  july: 7,
  august: 8,
  september: 9,
  october: 10,
  november: 11,
  december: 12,
};

const MONTH_NAMES = Object.keys(MONTHS).join("|");
const WEEKDAY_NAMES =
  "monday|tuesday|wednesday|thursday|friday|saturday|sunday";
const ORDINAL = "(?:st|nd|rd|th)";

/** Matches calendar dates embedded in free-form prose. */
const PROSE_DATE_REGEX = new RegExp(
  String.raw`(?:(?:${WEEKDAY_NAMES}),?\s+)?(?:` +
    // Month-first: "September 12th", "July 26, 2026"
    String.raw`(${MONTH_NAMES})\s+(\d{1,2})${ORDINAL}?(?:,?\s+(\d{4}))?` +
    String.raw`|` +
    // Day-first: "12th September", "14 November 2025"
    String.raw`(\d{1,2})${ORDINAL}?\s+(${MONTH_NAMES})(?:,?\s+(\d{4}))?` +
    String.raw`)`,
  "gi",
);

export function parsePromotionDates(
  promotionDates: string[] | null,
): DateRange {
  if (promotionDates == null || promotionDates.length === 0) {
    return { start: null, end: null };
  }

  let earliestStart: string | null = null;
  let latestEnd: string | null = null;

  for (const raw of promotionDates) {
    // Swift trims whitespace/newlines and "." from both ends.
    const trimmed = raw.replace(/^[\s.]+/, "").replace(/[\s.]+$/, "");
    if (trimmed.length === 0) continue;

    const parsed = parseLine(trimmed);
    // (Swift prints a debug line here; intentionally omitted.)
    if (parsed.start !== null) {
      earliestStart = minDate(earliestStart, parsed.start);
    }
    if (parsed.end !== null) {
      latestEnd = maxDate(latestEnd, parsed.end);
    }
  }

  return { start: earliestStart, end: latestEnd };
}

/**
 * Scans free-form deal text for calendar dates and returns a promotion range.
 * One date → start = end; multiple → min start / max end.
 */
export function parsePromotionDatesFromDealText(parts: string[]): DateRange {
  const dates: string[] = [];
  for (const part of parts) {
    if (part.length === 0) continue;
    dates.push(...extractDatesFromText(part));
  }

  if (dates.length === 0) {
    return { start: null, end: null };
  }

  let earliest: string | null = null;
  let latest: string | null = null;
  for (const date of dates) {
    earliest = minDate(earliest, date);
    latest = maxDate(latest, date);
  }
  return { start: earliest, end: latest };
}

export function extractDatesFromText(text: string): string[] {
  const year = new Date().getFullYear();
  const dates: string[] = [];
  PROSE_DATE_REGEX.lastIndex = 0;

  for (const match of text.matchAll(PROSE_DATE_REGEX)) {
    const date = dateFromProseMatch(match, year);
    if (date !== null) {
      dates.push(date);
    }
  }
  return dates;
}

function dateFromProseMatch(
  match: RegExpMatchArray,
  defaultYear: number,
): string | null {
  // Month-first groups: 1=month, 2=day, 3=year?
  if (match[1] !== undefined && match[2] !== undefined) {
    const explicitYear =
      match[3] !== undefined ? Number.parseInt(match[3], 10) : defaultYear;
    return buildDate(explicitYear, match[1], Number.parseInt(match[2], 10));
  }
  // Day-first groups: 4=day, 5=month, 6=year?
  if (match[4] !== undefined && match[5] !== undefined) {
    const explicitYear =
      match[6] !== undefined ? Number.parseInt(match[6], 10) : defaultYear;
    return buildDate(explicitYear, match[5], Number.parseInt(match[4], 10));
  }
  return null;
}

function parseLine(text: string): DateRange {
  const lower = text.toLowerCase();

  const fromThroughRange = parseFromThroughEndOfMonth(text);
  if (fromThroughRange !== null) {
    return fromThroughRange;
  }

  if (lower.startsWith("until ")) {
    const remainder = text.slice(6).trim();
    const end = parseDate(remainder, null);
    return { start: null, end };
  }

  if (lower.startsWith("from ")) {
    const remainder = text.slice(5).trim();
    const start = parseDate(remainder, null);
    return { start, end: null };
  }

  const rangeParts = splitRange(text);
  if (rangeParts !== null) {
    const endYear = yearFrom(rangeParts.end);
    const startYear = yearFrom(rangeParts.start) ?? endYear;
    const start = parseDate(rangeParts.start, startYear);
    const end = parseDate(rangeParts.end, endYear ?? startYear);
    return { start, end };
  }

  const date = parseDate(text, null);
  if (date !== null) {
    return { start: date, end: date };
  }

  return { start: null, end: null };
}

function parseFromThroughEndOfMonth(text: string): DateRange | null {
  const regex =
    /^from\s+(.+?)\s+through\s+to\s+the\s+end\s+of\s+([a-z]+)(?:\s+(\d{4}))?$/i;
  const match = regex.exec(text);
  if (!match) return null;

  const startText = match[1]!.trim();
  const monthText = match[2]!.trim();
  const explicitYear =
    match[3] !== undefined ? Number.parseInt(match[3], 10) : null;

  const start = parseDate(startText, explicitYear);
  const inferredYear =
    explicitYear ??
    (start !== null ? yearOf(start) : null) ??
    new Date().getFullYear();
  const end = endOfMonth(monthText, inferredYear);

  if (start === null && end === null) return null;
  return { start, end };
}

function splitRange(text: string): { start: string; end: string } | null {
  const separators = [" \u2013 ", " \u2014 ", " - ", " to "];
  for (const separator of separators) {
    const parts = text.split(separator);
    if (parts.length === 2) {
      const start = parts[0]!.trim();
      const end = parts[1]!.trim();
      if (start.length === 0 || end.length === 0) continue;
      return { start, end };
    }
  }
  return null;
}

function yearFrom(text: string): number | null {
  const match = /\b(?:19|20)\d{2}\b/.exec(text);
  if (!match) return null;
  return Number.parseInt(match[0], 10);
}

function parseDate(text: string, referenceYear: number | null): string | null {
  const trimmed = text.trim();
  if (trimmed.length === 0) return null;

  const withoutWeekday = stripWeekdayPrefix(trimmed);
  const year =
    yearFrom(withoutWeekday) ?? referenceYear ?? new Date().getFullYear();

  // Formats with an explicit year (weekday prefix already stripped):
  //   "d[st] MMMM yyyy", "MMMM d[st], yyyy", "MMMM d[st] yyyy"
  let m =
    /^(\d{1,2})(?:st|nd|rd|th)?\s+([a-z]+)\s+(\d{4})$/i.exec(withoutWeekday);
  if (m) {
    const date = buildDate(
      Number.parseInt(m[3]!, 10),
      m[2]!,
      Number.parseInt(m[1]!, 10),
    );
    if (date !== null) return date;
  }

  m = /^([a-z]+)\s+(\d{1,2})(?:st|nd|rd|th)?,?\s+(\d{4})$/i.exec(
    withoutWeekday,
  );
  if (m) {
    const date = buildDate(
      Number.parseInt(m[3]!, 10),
      m[1]!,
      Number.parseInt(m[2]!, 10),
    );
    if (date !== null) return date;
  }

  // Formats without a year: "d[st] MMMM", "MMMM d[st]"
  m = /^(\d{1,2})(?:st|nd|rd|th)?\s+([a-z]+)$/i.exec(withoutWeekday);
  if (m) {
    const date = buildDate(year, m[2]!, Number.parseInt(m[1]!, 10));
    if (date !== null) return date;
  }

  m = /^([a-z]+)\s+(\d{1,2})(?:st|nd|rd|th)?$/i.exec(withoutWeekday);
  if (m) {
    const date = buildDate(year, m[1]!, Number.parseInt(m[2]!, 10));
    if (date !== null) return date;
  }

  return null;
}

function buildDate(
  year: number,
  monthName: string,
  day: number,
): string | null {
  const month = MONTHS[monthName.toLowerCase()];
  if (month === undefined) return null;
  if (!(day >= 1 && day <= daysInMonth(year, month))) return null;
  return formatDate(year, month, day);
}

function stripWeekdayPrefix(text: string): string {
  return text.replace(
    /^(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday),?\s+/i,
    "",
  );
}

function endOfMonth(monthText: string, year: number): string | null {
  const month = MONTHS[monthText.toLowerCase()];
  if (month === undefined) return null;
  return formatDate(year, month, daysInMonth(year, month));
}

function daysInMonth(year: number, month: number): number {
  // month is 1-based; day 0 of the next month is the last day of this month.
  return new Date(year, month, 0).getDate();
}

function formatDate(year: number, month: number, day: number): string {
  const mm = String(month).padStart(2, "0");
  const dd = String(day).padStart(2, "0");
  return `${year}-${mm}-${dd}`;
}

function yearOf(date: string): number {
  return Number.parseInt(date.slice(0, 4), 10);
}

// yyyy-MM-dd strings compare lexicographically in chronological order.
function minDate(lhs: string | null, rhs: string): string {
  if (lhs === null) return rhs;
  return lhs < rhs ? lhs : rhs;
}

function maxDate(lhs: string | null, rhs: string): string {
  if (lhs === null) return rhs;
  return lhs > rhs ? lhs : rhs;
}
