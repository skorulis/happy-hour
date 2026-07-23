/**
 * Ported from `DealScraper/DealScraper/Service/DealTextNormalizer.swift`
 * (including the `String.cleanLine()` extension).
 */

// Matches Swift `CharacterSet.newlines` closely enough for LLM-sourced text.
const NEWLINE_SPLIT = /[\n\r\u2028\u2029\u0085\u000b\u000c]/;

export function prepareTitle(title: string): string {
  return title.split(NEWLINE_SPLIT).join(" ");
}

export function prepareDetails(details: string[]): string[] {
  return details.map((d) => d.trim()).filter((d) => d.length > 0);
}

export function formatTitle(title: string): string {
  if (title.length === 0 || isPriceLine(title)) return title;
  return lowercaseUnitsAfterNumbers(capitalized(title));
}

export function normalizeDetails(details: string[]): string[] {
  return details.map(sentenceCased);
}

export function normalizeConditions(conditions: string[]): string[] {
  return conditions.map(normalizeCondition).filter((c) => c.length > 0);
}

export function comparisonKey(line: string): string {
  return line
    .trim()
    .toLowerCase()
    .split(/\s+/)
    .filter((s) => s.length > 0)
    .join(" ");
}

const PRICE_LINE_PATTERNS = [
  /^\$\s*\d+(?:\.\d{1,2})?[a-z]*$/i,
  /^half[\s-]?price$/i,
];

export function isPriceLine(line: string): boolean {
  const trimmed = line.trim();
  if (trimmed.length === 0) return false;
  return PRICE_LINE_PATTERNS.some((pattern) => pattern.test(trimmed));
}

const UNITS_AFTER_NUMBER_PATTERN =
  /(\d+(?:\.\d+)?)(\s*)(kg|ml|mg|lbs|lb|oz|cl|gm|g|l|am|pm|pp)\b/gi;

function lowercaseUnitsAfterNumbers(title: string): string {
  return title.replace(
    UNITS_AFTER_NUMBER_PATTERN,
    (_match, num: string, space: string, unit: string) =>
      num + space + unit.toLowerCase(),
  );
}

/**
 * Swift `String.capitalized`: uppercases the first letter of each word and
 * lowercases the rest. Word boundaries occur at any non-letter character,
 * except an apostrophe sitting between two letters (a contraction like
 * "won't"), which is treated as part of the word.
 */
function capitalized(str: string): string {
  const chars = Array.from(str);
  let out = "";
  for (let i = 0; i < chars.length; i++) {
    const ch = chars[i]!;
    if (isLetter(ch)) {
      out += isWordStart(chars, i) ? ch.toUpperCase() : ch.toLowerCase();
    } else {
      out += ch;
    }
  }
  return out;
}

function isLetter(ch: string): boolean {
  return /\p{L}/u.test(ch);
}

function isApostrophe(ch: string): boolean {
  return ch === "'" || ch === "\u2019";
}

function isWordStart(chars: string[], i: number): boolean {
  if (i === 0) return true;
  const prev = chars[i - 1]!;
  if (isLetter(prev)) return false;
  if (isApostrophe(prev)) {
    const before = i >= 2 ? chars[i - 2]! : undefined;
    if (before !== undefined && isLetter(before)) {
      return false;
    }
    return true;
  }
  return true;
}

function sentenceCased(text: string): string {
  return text
    .split(NEWLINE_SPLIT)
    .map((line) => {
      if (line.length === 0) return line;
      return lowercaseUnitsAfterNumbers(sentenceCasedLine(line));
    })
    .join("\n");
}

function sentenceCasedLine(line: string): string {
  const lowercased = line.toLowerCase();
  const chars = Array.from(lowercased);
  const firstLetterIndex = chars.findIndex((c) => isLetter(c));
  if (firstLetterIndex < 0) {
    return lowercased;
  }
  chars[firstLetterIndex] = chars[firstLetterIndex]!.toUpperCase();
  return chars.join("");
}

function normalizeCondition(str: string): string {
  let trimmed = str.trim();
  if (trimmed.startsWith("*")) {
    trimmed = trimmed.slice(1).trim();
  }
  if (trimmed.startsWith("\\*")) {
    trimmed = trimmed.slice(2).trim();
  }
  return trimmed;
}

// Swift `String.cleanLine()`: trims whitespace/newlines plus the set `\*._|’-,:`.
const CLEAN_LINE_LEADING = /^[\s\\*._|\u2019,:-]+/;
const CLEAN_LINE_TRAILING = /[\s\\*._|\u2019,:-]+$/;

export function cleanLine(str: string): string {
  return str.replace(CLEAN_LINE_LEADING, "").replace(CLEAN_LINE_TRAILING, "");
}
