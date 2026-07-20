/**
 * Ported from `DealScraper/DealScraper/Service/DealTitleTrimmer.swift`.
 *
 * Strips leading/trailing day words, time strings, and orphaned separators from
 * deal titles.
 */

import { parseDealDay } from "./days";
import { toMinutes } from "./hours";
import { cleanLine } from "./text-normalizer";

const TIME = String.raw`(?:\d{1,2}(?:[:.]\d{2})?\s*(?:am|pm)?|\d{3,4}\s*(?:am|pm))`;

export function trimUntilStable(title: string): string {
  let result = title;
  for (;;) {
    const trimmed = trimOnce(result);
    if (trimmed === result) return trimmed;
    result = trimmed;
  }
}

export function trimOnce(title: string): string {
  let result = title.trim();
  if (result.length === 0) return result;

  result = cleanLine(result);
  result = stripDayWord(result, true);
  result = stripDayWord(result, false);

  const availableFromPattern = new RegExp(
    `\\s+available\\s+from\\s+(${TIME})\\s*$`,
    "i",
  );
  {
    const stripped = stripSuffix(availableFromPattern, result, [1]);
    if (stripped !== null) result = stripped;
  }

  const fullRangePattern = new RegExp(
    `\\s+(${TIME})\\s*(?:-|\u2013|\u2014|to|til|till|'til|until)\\s*(${TIME})\\s*$`,
    "i",
  );
  {
    const stripped = stripSuffix(fullRangePattern, result, [1, 2]);
    if (stripped !== null) result = stripped;
  }

  const partialRangePattern = new RegExp(
    `\\s+(${TIME})\\s*(?:-|\u2013|\u2014)\\s*$`,
    "i",
  );
  {
    const stripped = stripSuffix(partialRangePattern, result, [1]);
    if (stripped !== null) result = stripped;
  }

  const trailingTimePattern = new RegExp(`\\s+(${TIME})\\s*$`, "i");
  {
    const stripped = stripSuffix(trailingTimePattern, result, [1]);
    if (stripped !== null) result = stripped;
  }

  result = stripTrailingFromWord(result);
  result = stripTrailingEveryWord(result);
  result = stripTrailingOrphanSeparator(result);

  return result;
}

function splitOnSpaces(title: string): string[] {
  return title.split(" ").filter((s) => s.length > 0);
}

function stripDayWord(title: string, atStart: boolean): string {
  const parts = splitOnSpaces(title);
  if (parts.length === 0) return title;

  if (atStart) {
    if (
      parts.length > 1 &&
      parseDealDay(parts[0]!) !== null &&
      parts[1] === ":"
    ) {
      return parts.slice(2).join(" ");
    }

    const first = parts[0]!;
    if (first.endsWith(":") && parseDealDay(first.slice(0, -1)) !== null) {
      return parts.slice(1).join(" ");
    }

    if (parseDealDay(first) === null) return title;
    return parts.slice(1).join(" ");
  }

  if (parts.length > 1 && parseDealDay(parts[parts.length - 1]!) !== null) {
    return parts.slice(0, -1).join(" ");
  }
  return title;
}

function stripTrailingFromWord(title: string): string {
  const parts = splitOnSpaces(title);
  if (parts.length > 1 && parts[parts.length - 1]!.toLowerCase() === "from") {
    return parts.slice(0, -1).join(" ");
  }
  return title;
}

function stripTrailingEveryWord(title: string): string {
  const parts = splitOnSpaces(title);
  if (parts.length > 1 && parts[parts.length - 1]!.toLowerCase() === "every") {
    return parts.slice(0, -1).join(" ");
  }
  return title;
}

function stripTrailingOrphanSeparator(title: string): string {
  const match = /\s*(?:-|\u2013|\u2014)\s*$/.exec(title);
  if (!match) return title;
  return title.slice(0, match.index).trim();
}

function stripSuffix(
  pattern: RegExp,
  text: string,
  timeCaptureGroups: number[],
): string | null {
  const match = pattern.exec(text);
  if (!match) return null;

  for (const group of timeCaptureGroups) {
    const timeText = match[group];
    if (timeText === undefined) return null;
    if (toMinutes(timeText) === null) return null;
  }

  return text.slice(0, match.index).trim();
}
