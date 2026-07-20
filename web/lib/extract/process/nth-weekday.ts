/**
 * Ported from
 * `DealScraper/DealScraper/Service/Filter/NthWeekdayOfMonthDetector.swift`.
 *
 * Detects "nth weekday of the month" schedules (e.g. "First Tuesday of each
 * Month") which should be auto-rejected because the app only models weekly
 * recurrence.
 */

const WEEKDAY_PATTERN =
  "(?:mon(?:day)?|tues?(?:day)?|wed(?:nesday)?|thu(?:rs?)?(?:day)?|fri(?:day)?|sat(?:urday)?|sun(?:day)?)";

const ORDINAL_PATTERN = "(?:first|second|third|fourth|last|\\d+(?:st|nd|rd|th))";

const MONTH_QUALIFIER_PATTERN = "of\\s+(?:each|every|the)\\s+month";

const SLASH_MONTH_QUALIFIER_PATTERN =
  "of\\s+\\(\\s*each\\s*/\\s*every\\s*/\\s*the\\s*\\)\\s+month";

const SLASH_ORDINAL_PATTERN =
  "first\\s*/\\s*second\\s*/\\s*third\\s*/\\s*fourth\\s*/\\s*last";

const PATTERNS: RegExp[] = [
  `\\b${ORDINAL_PATTERN}\\s+${WEEKDAY_PATTERN}\\b[\\s\\S]*?${MONTH_QUALIFIER_PATTERN}\\b`,
  `\\b${ORDINAL_PATTERN}\\s+${WEEKDAY_PATTERN}\\b[\\s\\S]*?${SLASH_MONTH_QUALIFIER_PATTERN}\\b`,
  `\\(\\s*${SLASH_ORDINAL_PATTERN}\\s*\\)\\s+${WEEKDAY_PATTERN}\\b[\\s\\S]*?${MONTH_QUALIFIER_PATTERN}\\b`,
  `\\(\\s*${SLASH_ORDINAL_PATTERN}\\s*\\)\\s+${WEEKDAY_PATTERN}\\b[\\s\\S]*?${SLASH_MONTH_QUALIFIER_PATTERN}\\b`,
].map((pattern) => new RegExp(pattern, "i"));

function containsPattern(text: string): boolean {
  const trimmed = text.trim();
  if (trimmed.length === 0) return false;
  return PATTERNS.some((regex) => regex.test(trimmed));
}

function isMatchInTexts(texts: string[]): boolean {
  return texts.some((text) => containsPattern(text));
}

export function isNthWeekdayOfMonthMatch({
  title,
  details,
  conditions,
  days,
}: {
  title: string | null;
  details: string[];
  conditions: string[];
  days: string[];
}): boolean {
  const texts = [
    ...(title != null ? [title] : []),
    ...details,
    ...conditions,
    ...days,
  ];
  return isMatchInTexts(texts);
}
