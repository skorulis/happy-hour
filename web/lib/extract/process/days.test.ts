import { describe, expect, it } from "vitest";
import {
  isDayMentioned,
  parseAllDealDays,
  parseDealDay,
} from "@/lib/extract/process/days";

// Ported from DealScraper/DealScraperTests/Model/DealDayTests.swift

describe("parseDealDay", () => {
  it("parses full day names", () => {
    expect(parseDealDay("monday")).toBe("monday");
    expect(parseDealDay("Tuesday")).toBe("tuesday");
    expect(parseDealDay("  SUNDAY  ")).toBe("sunday");
  });

  it("parses abbreviations", () => {
    expect(parseDealDay("tues")).toBe("tuesday");
    expect(parseDealDay("thurs")).toBe("thursday");
    expect(parseDealDay("sun")).toBe("sunday");
    expect(parseDealDay("mon")).toBe("monday");
  });

  it("returns null for unparseable input", () => {
    expect(parseDealDay("")).toBeNull();
    expect(parseDealDay("notaday")).toBeNull();
  });
});

describe("parseAllDealDays", () => {
  it("finds days in verbatim lines", () => {
    expect(parseAllDealDays("EVERY TUES")).toEqual(["tuesday"]);
    expect(parseAllDealDays("CHEESEBURGER TUESDAYS")).toEqual(["tuesday"]);
    expect(
      parseAllDealDays("TUES - THURS 4PM - 6PM / FRI 3PM - 5PM"),
    ).toEqual(["tuesday", "wednesday", "thursday", "friday"]);
  });

  it("expands weekends", () => {
    expect(parseAllDealDays("WEEKENDS")).toEqual(["saturday", "sunday"]);
    expect(parseAllDealDays("weekend")).toEqual(["saturday", "sunday"]);
    expect(parseAllDealDays("Happy hour on weekends 5PM - 7PM")).toEqual([
      "saturday",
      "sunday",
    ]);
  });

  it("expands weekdays", () => {
    expect(parseAllDealDays("WEEKDAY")).toEqual([
      "monday",
      "tuesday",
      "wednesday",
      "thursday",
      "friday",
    ]);
    expect(parseAllDealDays("WEEKDAYS")).toEqual([
      "monday",
      "tuesday",
      "wednesday",
      "thursday",
      "friday",
    ]);
    expect(parseAllDealDays("EVERY WEEKDAY")).toEqual([
      "monday",
      "tuesday",
      "wednesday",
      "thursday",
      "friday",
    ]);
  });

  it("joins split day tokens", () => {
    expect(parseAllDealDays(["EVERY", "WEEKDAY"])).toEqual([
      "monday",
      "tuesday",
      "wednesday",
      "thursday",
      "friday",
    ]);
    expect(parseAllDealDays(["EVERY", "DAY"])).toEqual(["everyDay"]);
    expect(parseAllDealDays(["EVERY", "TUES"])).toEqual(["tuesday"]);
  });

  it("expands day ranges", () => {
    expect(parseAllDealDays("MONDAY - FRIDAY")).toEqual([
      "monday",
      "tuesday",
      "wednesday",
      "thursday",
      "friday",
    ]);
    expect(parseAllDealDays("MONDAY to FRIDAY")).toEqual([
      "monday",
      "tuesday",
      "wednesday",
      "thursday",
      "friday",
    ]);
    expect(parseAllDealDays("MONDAY TILL FRIDAY*")).toEqual([
      "monday",
      "tuesday",
      "wednesday",
      "thursday",
      "friday",
    ]);
    expect(parseAllDealDays("MON - FRI")).toEqual([
      "monday",
      "tuesday",
      "wednesday",
      "thursday",
      "friday",
    ]);
    expect(parseAllDealDays("MON-FRI")).toEqual([
      "monday",
      "tuesday",
      "wednesday",
      "thursday",
      "friday",
    ]);
    expect(parseAllDealDays("FRI - MON")).toEqual([
      "monday",
      "friday",
      "saturday",
      "sunday",
    ]);
  });
});

describe("isDayMentioned", () => {
  it("finds full names and abbreviations", () => {
    expect(isDayMentioned("Happy Hour every Friday")).toBe(true);
    expect(isDayMentioned("TUES - THURS 4PM - 6PM")).toBe(true);
    expect(isDayMentioned("Special offers on selected drinks")).toBe(false);
    expect(isDayMentioned("")).toBe(false);
  });
});
