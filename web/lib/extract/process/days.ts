/**
 * Ported from `DealScraper/DealScraper/Model/DealDay.swift`.
 *
 * Parses the days a deal is valid from free-form strings, including ranges
 * ("Mon - Fri"), abbreviations ("Tues"), and group words ("weekdays").
 */

import type { DealDay } from "./types";

const ALL_CASES: DealDay[] = [
  "monday",
  "tuesday",
  "wednesday",
  "thursday",
  "friday",
  "saturday",
  "sunday",
  "everyDay",
];

const WEEKDAY_ORDER: DealDay[] = [
  "monday",
  "tuesday",
  "wednesday",
  "thursday",
  "friday",
  "saturday",
  "sunday",
];

const ABBREVIATIONS: Record<string, DealDay> = {
  mon: "monday",
  tue: "tuesday",
  tues: "tuesday",
  wed: "wednesday",
  thu: "thursday",
  thur: "thursday",
  thurs: "thursday",
  fri: "friday",
  friyay: "friday",
  friyays: "friday",
  sat: "saturday",
  sun: "sunday",
  "every Day": "everyDay",
};

function escapeRegExp(str: string): string {
  return str.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

const DAY_TOKENS: string[] = (() => {
  const tokens = new Set<string>(WEEKDAY_ORDER);
  for (const [abbrev, day] of Object.entries(ABBREVIATIONS)) {
    if (day !== "everyDay") {
      tokens.add(abbrev);
    }
  }
  return Array.from(tokens).sort((a, b) => b.length - a.length);
})();

const DAY_RANGE_REGEX: RegExp = (() => {
  const tokenPattern = DAY_TOKENS.map(escapeRegExp).join("|");
  const pattern = `\\b(${tokenPattern})\\s*(?:-|\u2013|\u2014|to|til|till|'til|until|through|thru)\\s*(${tokenPattern})\\b`;
  return new RegExp(pattern, "gi");
})();

export function parseDealDay(str: string): DealDay | null {
  const normalized = str.trim().toLowerCase();
  if (normalized.length === 0) return null;

  if ((ALL_CASES as string[]).includes(normalized)) {
    return normalized as DealDay;
  }
  return ABBREVIATIONS[normalized] ?? null;
}

export function parseAllDealDays(input: string | string[]): DealDay[] {
  if (Array.isArray(input)) {
    const trimmed = input.map((s) => s.trim()).filter((s) => s.length > 0);
    if (trimmed.length === 0) return [];
    return parseAllInString(trimmed.join(" "));
  }
  return parseAllInString(input);
}

function parseAllInString(str: string): DealDay[] {
  const day = parseDealDay(str);
  if (day !== null) {
    return [day];
  }

  const normalized = str.trim().toLowerCase();
  if (normalized.length === 0) return [];

  if (
    normalized.includes("every day") ||
    normalized.replace(/ /g, "") === "everyday"
  ) {
    return ["everyDay"];
  }

  const found = new Set<DealDay>();

  if (/\bweekdays?\b/.test(normalized)) {
    found.add("monday");
    found.add("tuesday");
    found.add("wednesday");
    found.add("thursday");
    found.add("friday");
  }

  if (/\bweekends?\b/.test(normalized)) {
    found.add("saturday");
    found.add("sunday");
  }

  parseDayRanges(normalized, found);

  for (const dayCase of ALL_CASES) {
    if (normalized.includes(dayCase)) {
      found.add(dayCase);
    }
  }

  const abbreviationsByLength = Object.entries(ABBREVIATIONS).sort(
    (a, b) => b[0].length - a[0].length,
  );
  for (const [abbrev, dayValue] of abbreviationsByLength) {
    const regex = new RegExp(`\\b${escapeRegExp(abbrev)}\\b`);
    if (regex.test(normalized)) {
      found.add(dayValue);
    }
  }

  return ALL_CASES.filter((c) => found.has(c));
}

export function isDayMentioned(str: string): boolean {
  return parseAllDealDays(str).length > 0;
}

function parseDayRanges(normalized: string, found: Set<DealDay>): void {
  DAY_RANGE_REGEX.lastIndex = 0;
  let match: RegExpExecArray | null;
  while ((match = DAY_RANGE_REGEX.exec(normalized)) !== null) {
    const startDay = parseDealDay(match[1]!);
    const endDay = parseDealDay(match[2]!);
    if (
      startDay === null ||
      endDay === null ||
      startDay === "everyDay" ||
      endDay === "everyDay"
    ) {
      continue;
    }
    for (const day of expandRange(startDay, endDay)) {
      found.add(day);
    }
  }
}

function expandRange(start: DealDay, end: DealDay): DealDay[] {
  const startIndex = WEEKDAY_ORDER.indexOf(start);
  const endIndex = WEEKDAY_ORDER.indexOf(end);
  if (startIndex < 0 || endIndex < 0) {
    return [start, end];
  }

  if (startIndex <= endIndex) {
    return WEEKDAY_ORDER.slice(startIndex, endIndex + 1);
  }
  return [
    ...WEEKDAY_ORDER.slice(startIndex),
    ...WEEKDAY_ORDER.slice(0, endIndex + 1),
  ];
}

export function calendarWeekday(day: DealDay): number {
  switch (day) {
    case "sunday":
      return 1;
    case "monday":
      return 2;
    case "tuesday":
      return 3;
    case "wednesday":
      return 4;
    case "thursday":
      return 5;
    case "friday":
      return 6;
    case "saturday":
      return 7;
    case "everyDay":
      return 1;
  }
}

export function scheduleDays(day: DealDay): DealDay[] {
  if (day === "everyDay") {
    return [
      "sunday",
      "monday",
      "tuesday",
      "wednesday",
      "thursday",
      "friday",
      "saturday",
    ];
  }
  return [day];
}
