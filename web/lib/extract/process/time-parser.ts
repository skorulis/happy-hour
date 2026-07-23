/**
 * Ported from `DealScraper/DealScraper/Service/DealTimeParser.swift`.
 *
 * Extracts `DealHours` from free-form time strings, handling a wide range of
 * formats seen in scraped/OCR'd menus.
 */

import { makeBetween, parseDealHours, toMinutes } from "./hours";
import type { DealHours } from "./types";
import { uniqueHours } from "./types";

const TIME = String.raw`\d{1,2}(?:[:.]\d{2})?\s*(?:am|pm)?`;

export function parseTimes(strings: string[]): DealHours[] {
  const trimmed = strings
    .map(sanitizeTimeString)
    .filter((s) => s.length > 0);
  if (trimmed.length === 0) return [];

  if (trimmed.every(isAllDayToken)) {
    return [{ kind: "allDay" }];
  }

  {
    const range = parseFromDrawnAtRange(trimmed);
    if (range !== null) return [range];
  }

  {
    const range = parseHyphenContinuedRange(trimmed);
    if (range !== null) return [range];
  }

  const times: DealHours[] = [];
  for (const string of trimmed) {
    const time =
      parseFromDrawnRange(string) ??
      parseHoursFromRange(string) ??
      parseTillOrUntilTime(string) ??
      parseArriveAtTime(string) ??
      parseBetweenTime(string) ??
      parseDealHours(string) ??
      parseEmbeddedTimeRange(string) ??
      parseMultipleTimesAsRange(string);
    if (time !== null) {
      times.push(time);
    } else {
      times.push(...timesInText(string));
    }
  }
  return uniqueHours(times);
}

export function timesInText(text: string): DealHours[] {
  text = sanitizeTimeString(text);
  {
    const time = parseFromDrawnRange(text);
    if (time !== null) return [time];
  }
  {
    const time = parseHoursFromRange(text);
    if (time !== null) return [time];
  }
  {
    const time = parseTillOrUntilTime(text);
    if (time !== null) return [time];
  }
  {
    const time = parseArriveAtTime(text);
    if (time !== null) return [time];
  }
  {
    const time = parseBetweenTime(text);
    if (time !== null) return [time];
  }
  {
    const time = parseDealHours(text);
    if (time !== null) return [time];
  }
  {
    const time = parseEmbeddedTimeRange(text);
    if (time !== null) return [time];
  }
  {
    const time = parseMultipleTimesAsRange(text);
    if (time !== null) return [time];
  }

  const regex = /(?<!\d)(\d{1,2}(?:[:.]\d{2})?\s*(?:am|pm)?)(?!\d)/gi;
  const result: DealHours[] = [];
  let match: RegExpExecArray | null;
  while ((match = regex.exec(text)) !== null) {
    const parsed = parseDealHours(match[1]!);
    if (parsed !== null) result.push(parsed);
  }
  if (result.length > 0) return result;

  const meal = parseMealPeriod(text);
  return meal !== null ? [meal] : [];
}

/**
 * Named meal periods used when no clock times are present, e.g. "MON TO FRI LUNCH".
 * Default lunch window matches the meal-time adjustment in `to-processed-deal`.
 */
function parseMealPeriod(text: string): DealHours | null {
  const lowercased = text.toLowerCase();
  const hasLunch = /\blunch\b/.test(lowercased);
  const hasNightString =
    /\bdinner\b/.test(lowercased) ||
    /\bevening\b/.test(lowercased) ||
    /\bnight\b/.test(lowercased);

  if (hasLunch && !hasNightString) {
    return makeBetween(12 * 60, 14 * 60);
  }
  return null;
}

function stripTimeLabelPrefix(str: string): string {
  const regex = /^(?:times?\s*[-:]|happy\s*hours?)\s*/i;
  const match = regex.exec(str);
  if (!match) return str;
  return str.slice(match[0].length).trim();
}

function normalizeDottedMeridiem(str: string): string {
  return str.replace(/a\.m\.?/gi, "am").replace(/p\.m\.?/gi, "pm");
}

/** OCR and font substitutions sometimes render "to" as "tº" or "t°". */
function normalizeOCRToToken(str: string): string {
  return str.replace(/t[\u00ba\u00b00]/gi, "to");
}

function sanitizeTimeString(str: string): string {
  let result = str
    .replace(/\u2019/g, "'")
    .replace(/\u2018/g, "'")
    .trim();
  result = normalizeDottedMeridiem(result);
  result = normalizeOCRToToken(result);
  result = stripTimeLabelPrefix(result);
  result = stripListMarkers(result);
  const wrappers: [string, string][] = [
    ["(", ")"],
    ["[", "]"],
    ["*", "*"],
    ["_", "_"],
  ];
  let changed = true;
  while (changed) {
    changed = false;
    result = result.trim();
    for (const [open, close] of wrappers) {
      if (
        result.length > 1 &&
        result[0] === open &&
        result[result.length - 1] === close
      ) {
        result = result.slice(1, -1);
        changed = true;
      }
    }
  }
  return result;
}

function stripListMarkers(str: string): string {
  const markers = ["\u2022", "\u2023", "\u00b7", "\u25e6", "\u2219"];
  let result = str;
  let changed = true;
  while (changed) {
    changed = false;
    result = result.trim();
    for (const marker of markers) {
      if (result[0] === marker) {
        result = result.slice(1);
        changed = true;
      }
      if (result[result.length - 1] === marker) {
        result = result.slice(0, -1);
        changed = true;
      }
    }
  }
  return result;
}

function isAllDayToken(str: string): boolean {
  switch (str.toLowerCase()) {
    case "all day":
    case "all-day":
    case "allday":
      return true;
    default:
      return false;
  }
}

function parseTillOrUntilTime(text: string): DealHours | null {
  const trimmed = text.trim();
  if (trimmed.length === 0) return null;

  const till = String.raw`(?:'?(?:till|til)'?|until)`;

  const fromTillPattern = new RegExp(
    `from\\s+(${TIME})\\s+${till}\\s+(${TIME})`,
    "i",
  );
  {
    const match = fromTillPattern.exec(trimmed);
    if (match) {
      const start = toMinutes(match[1]!);
      const end = toMinutes(match[2]!);
      if (start !== null && end !== null) return makeBetween(start, end);
    }
  }

  const tillRangePattern = new RegExp(
    `(${TIME})\\s+${till}\\s+(${TIME})`,
    "i",
  );
  {
    const match = tillRangePattern.exec(trimmed);
    if (match) {
      const start = toMinutes(match[1]!);
      const end = toMinutes(match[2]!);
      if (start !== null && end !== null) return makeBetween(start, end);
    }
  }

  const tillOnlyPattern = new RegExp(`${till}\\s+(${TIME})`, "i");
  {
    const match = tillOnlyPattern.exec(trimmed);
    if (match) {
      const end = toMinutes(match[1]!);
      if (end !== null) return { kind: "between", start: 0, end };
    }
  }

  return null;
}

function parseFromDrawnRange(text: string): DealHours | null {
  const trimmed = text.trim();
  if (trimmed.length === 0) return null;

  // "FROM 4PM DRAWN 6PM", "SALES 5.30PM DRAWS 7.30PM"
  const pattern = new RegExp(
    `(?:from|sales?)\\s+(${TIME}).*draw(?:n|s)?(?:\\s+(?:from|at))?\\s+(${TIME})`,
    "i",
  );
  const match = pattern.exec(trimmed);
  if (!match) return null;
  const start = toMinutes(match[1]!);
  const end = toMinutes(match[2]!);
  if (start === null || end === null) return null;
  return makeBetween(start, end);
}

function parseFromDrawnAtRange(strings: string[]): DealHours | null {
  // Match end phrases first so "DRAWS FROM 6:30PM" is not treated as a start.
  const drawsFromPattern = new RegExp(
    `^(?:.*\\s)?draw(?:n|s)?\\s+from\\s+(${TIME})$`,
    "i",
  );
  const drawnAtPattern = new RegExp(
    `^(?:.*\\s)?drawn(?:\\s+at)?\\s+(${TIME})$`,
    "i",
  );
  const fromOnlyPattern = new RegExp(`^(?:.*\\s)?from\\s+(${TIME})$`, "i");

  let startMinutes: number | null = null;
  let endMinutes: number | null = null;

  for (const string of strings) {
    const endCapture =
      firstCaptureMinutes(string, drawsFromPattern) ??
      firstCaptureMinutes(string, drawnAtPattern);
    if (endCapture !== null) {
      endMinutes = endCapture;
    } else {
      const startCapture = firstCaptureMinutes(string, fromOnlyPattern);
      if (startCapture !== null) {
        startMinutes = startCapture;
      }
    }
  }

  if (startMinutes === null || endMinutes === null) return null;
  return makeBetween(startMinutes, endMinutes);
}

/** "7.30 pm" on one line and "-10.30 pm" on the next → 7:30 PM–10:30 PM. */
function parseHyphenContinuedRange(strings: string[]): DealHours | null {
  // NOTE: the Swift original uses `^time$` with no capture group, which makes
  // `range(at: 1)` throw at runtime. The corresponding test expects a parsed
  // range, so we add the capture group the test intends.
  const timeOnlyPattern = new RegExp(`^(${TIME})$`, "i");
  const hyphenEndPattern = new RegExp(`^[-\u2013\u2014]\\s*(${TIME})$`, "i");

  for (let index = 1; index < strings.length; index++) {
    const end = firstCaptureMinutes(strings[index]!, hyphenEndPattern);
    const start = firstCaptureMinutes(strings[index - 1]!, timeOnlyPattern);
    if (end === null || start === null) continue;
    return makeBetween(start, end);
  }
  return null;
}

function firstCaptureMinutes(str: string, pattern: RegExp): number | null {
  const match = pattern.exec(str);
  if (!match || match[1] === undefined) return null;
  return toMinutes(match[1]);
}

function parseMultipleTimesAsRange(text: string): DealHours | null {
  const trimmed = text.trim();
  if (trimmed.length === 0) return null;

  if (!/[,&]|(?:\band\b)/i.test(trimmed)) {
    return null;
  }

  const timePattern = /(?<!\d)(\d{1,2}(?:[:.]\d{2})?\s*(?:am|pm)?)(?!\d)/gi;
  const minutes: number[] = [];
  let match: RegExpExecArray | null;
  while ((match = timePattern.exec(trimmed)) !== null) {
    const m = toMinutes(match[1]!);
    if (m !== null) minutes.push(m);
  }

  if (minutes.length < 2) return null;
  const earliest = Math.min(...minutes);
  const latest = Math.max(...minutes);
  return makeBetween(earliest, latest);
}

function parseHoursFromRange(text: string): DealHours | null {
  const trimmed = text.trim();
  if (trimmed.length === 0) return null;

  const match = /^\d+\s*(?:hrs?|hours?)\s+from\s+(.+)$/i.exec(trimmed);
  if (!match) return null;

  return parseDealHours(match[1]!);
}

function parseBetweenTime(text: string): DealHours | null {
  const trimmed = text.trim();
  if (trimmed.length === 0) return null;

  const betweenPattern = new RegExp(
    `between\\s+(${TIME})\\s*(?:-|\u2013|\u2014|to)\\s*(${TIME})`,
    "i",
  );
  const match = betweenPattern.exec(trimmed);
  if (!match) return null;
  const start = toMinutes(match[1]!);
  const end = toMinutes(match[2]!);
  if (start === null || end === null) return null;
  return makeBetween(start, end);
}

/** Extracts a time range embedded in surrounding label text, e.g. "BISTRO OPEN 5PM-8:30PM". */
function parseEmbeddedTimeRange(text: string): DealHours | null {
  const trimmed = text.trim();
  if (trimmed.length === 0) return null;

  const pattern = new RegExp(
    `(?<!\\d)(${TIME})\\s*(?:-|\u2013|\u2014|to)\\s*(${TIME})(?!\\d)`,
    "i",
  );
  const match = pattern.exec(trimmed);
  if (!match) return null;
  const start = toMinutes(match[1]!);
  const end = toMinutes(match[2]!);
  if (start === null || end === null) return null;
  return makeBetween(start, end);
}

/** "Arrive at 6:00PM for 6:30PM start" → from arrival through midnight. */
function parseArriveAtTime(text: string): DealHours | null {
  const trimmed = text.trim();
  if (trimmed.length === 0) return null;

  const pattern = new RegExp(
    `arrive\\s+at\\s+(${TIME})(?:\\s+for\\s+${TIME}\\s+start)?`,
    "i",
  );
  const match = pattern.exec(trimmed);
  if (!match) return null;
  const start = toMinutes(match[1]!);
  if (start === null) return null;
  return makeBetween(start, 0);
}
