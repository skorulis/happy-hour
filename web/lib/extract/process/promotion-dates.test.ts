import { describe, expect, it } from "vitest";
import {
  extractDatesFromText,
  parsePromotionDates,
  parsePromotionDatesFromDealText,
} from "@/lib/extract/process/promotion-dates";

// Ported from DealScraper/DealScraperTests/PromotionDateParserTests.swift
// Swift returns Date objects; here we return local `yyyy-MM-dd` strings.

describe("parsePromotionDates", () => {
  it("parses date range with year on end", () => {
    const result = parsePromotionDates([
      "Friday, 14 November \u2013 Monday, 1 December 2025",
    ]);
    expect(result.start).toBe("2025-11-14");
    expect(result.end).toBe("2025-12-01");
  });

  it("parses single date", () => {
    const result = parsePromotionDates(["14 November 2025"]);
    expect(result.start).toBe(result.end);
    expect(result.start).toBe("2025-11-14");
  });

  it("parses until prefix", () => {
    const result = parsePromotionDates(["until 31 December 2025"]);
    expect(result.start).toBeNull();
    expect(result.end).toBe("2025-12-31");
  });

  it("parses from prefix", () => {
    const result = parsePromotionDates(["from 14 November 2025"]);
    expect(result.start).toBe("2025-11-14");
    expect(result.end).toBeNull();
  });

  it("parses from-through-end-of-month range", () => {
    const result = parsePromotionDates([
      "from Monday 18 May through to the end of June.",
    ]);
    const year = new Date().getFullYear();
    expect(result.start).toBe(`${year}-05-18`);
    expect(result.end).toBe(`${year}-06-30`);
  });

  it("returns null for unparseable text", () => {
    const result = parsePromotionDates(["Black Friday only"]);
    expect(result.start).toBeNull();
    expect(result.end).toBeNull();
  });

  it("merges multiple lines to widest range", () => {
    const result = parsePromotionDates([
      "from 1 November 2025",
      "until 31 December 2025",
    ]);
    expect(result.start).toBe("2025-11-01");
    expect(result.end).toBe("2025-12-31");
  });

  it("returns null for null input", () => {
    const result = parsePromotionDates(null);
    expect(result.start).toBeNull();
    expect(result.end).toBeNull();
  });

  it("parses ordinal single date", () => {
    const result = parsePromotionDates(["12th September 2026"]);
    expect(result.start).toBe("2026-09-12");
    expect(result.end).toBe("2026-09-12");
  });
});

describe("extractDatesFromText", () => {
  it("finds month-first date with weekday and ordinal", () => {
    const year = new Date().getFullYear();
    expect(
      extractDatesFromText(
        "Shake & Bake are back Saturday September 12th for another show we all know and love.",
      ),
    ).toEqual([`${year}-09-12`]);
  });

  it("finds day-first ordinal dates", () => {
    const year = new Date().getFullYear();
    expect(extractDatesFromText("Join us on Sunday 26th July at 6pm")).toEqual([
      `${year}-07-26`,
    ]);
  });

  it("finds multiple dates in one blob", () => {
    const year = new Date().getFullYear();
    expect(
      extractDatesFromText(
        "Upcoming dates:\n* July 27th\n* August 31st\n* September 21st",
      ),
    ).toEqual([`${year}-07-27`, `${year}-08-31`, `${year}-09-21`]);
  });

  it("finds dates with explicit years", () => {
    expect(extractDatesFromText("Show on September 12th, 2027")).toEqual([
      "2027-09-12",
    ]);
  });

  it("ignores weekly copy without calendar dates", () => {
    expect(
      extractDatesFromText(
        "Join us every Saturday night from 8pm–11pm for Duelling Pianos.",
      ),
    ).toEqual([]);
  });
});

describe("parsePromotionDatesFromDealText", () => {
  it("sets start and end to a single embedded date", () => {
    const year = new Date().getFullYear();
    const result = parsePromotionDatesFromDealText([
      "Shake & Bake are back Saturday September 12th for another show we all know and love.",
    ]);
    expect(result.start).toBe(`${year}-09-12`);
    expect(result.end).toBe(`${year}-09-12`);
  });

  it("uses min/max range for multiple dates", () => {
    const year = new Date().getFullYear();
    const result = parsePromotionDatesFromDealText([
      "Upcoming dates:",
      "July 27th",
      "August 31st",
      "September 21st",
    ]);
    expect(result.start).toBe(`${year}-07-27`);
    expect(result.end).toBe(`${year}-09-21`);
  });

  it("returns null when no dates found", () => {
    const result = parsePromotionDatesFromDealText([
      "Happy Hour every Friday 4PM - 6PM",
    ]);
    expect(result.start).toBeNull();
    expect(result.end).toBeNull();
  });
});
