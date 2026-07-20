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
  //   "d MMMM yyyy", "MMMM d, yyyy", "MMMM d yyyy"
  let m = /^(\d{1,2})\s+([a-z]+)\s+(\d{4})$/i.exec(withoutWeekday);
  if (m) {
    const date = buildDate(
      Number.parseInt(m[3]!, 10),
      m[2]!,
      Number.parseInt(m[1]!, 10),
    );
    if (date !== null) return date;
  }

  m = /^([a-z]+)\s+(\d{1,2}),?\s+(\d{4})$/i.exec(withoutWeekday);
  if (m) {
    const date = buildDate(
      Number.parseInt(m[3]!, 10),
      m[1]!,
      Number.parseInt(m[2]!, 10),
    );
    if (date !== null) return date;
  }

  // Formats without a year: "d MMMM", "MMMM d"
  m = /^(\d{1,2})\s+([a-z]+)$/i.exec(withoutWeekday);
  if (m) {
    const date = buildDate(year, m[2]!, Number.parseInt(m[1]!, 10));
    if (date !== null) return date;
  }

  m = /^([a-z]+)\s+(\d{1,2})$/i.exec(withoutWeekday);
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
