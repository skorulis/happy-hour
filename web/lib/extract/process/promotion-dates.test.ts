import { describe, expect, it } from "vitest";
import { parsePromotionDates } from "@/lib/extract/process/promotion-dates";

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
});
