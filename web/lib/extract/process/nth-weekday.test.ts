import { describe, expect, it } from "vitest";
import { isNthWeekdayOfMonthMatch } from "@/lib/extract/process/nth-weekday";

// Ported from DealScraper/DealScraperTests/NthWeekdayOfMonthDetectorTests.swift

describe("isNthWeekdayOfMonthMatch", () => {
  it("matches standard ordinal in details", () => {
    expect(
      isNthWeekdayOfMonthMatch({
        title: "Steak Night",
        details: ["First Tuesday of each Month"],
        conditions: [],
        days: [],
      }),
    ).toBe(true);
  });

  it("matches slash notation in details", () => {
    expect(
      isNthWeekdayOfMonthMatch({
        title: null,
        details: [
          "(First/Second/Third/Fourth/Last) Tuesday of (each/every/the) Month",
        ],
        conditions: [],
        days: [],
      }),
    ).toBe(true);
  });

  it("matches ordinal in days", () => {
    expect(
      isNthWeekdayOfMonthMatch({
        title: "Special",
        details: ["$10 meals"],
        conditions: [],
        days: ["Last Friday of the month"],
      }),
    ).toBe(true);
  });

  it("matches numeric ordinal in conditions", () => {
    expect(
      isNthWeekdayOfMonthMatch({
        title: "Wine Night",
        details: [],
        conditions: ["2nd Wed of every month"],
        days: ["Wednesday"],
      }),
    ).toBe(true);
  });

  it("matches every-ordinal-weekday-of-month phrase", () => {
    expect(
      isNthWeekdayOfMonthMatch({
        title: "AZUCAR latin nights",
        details: [],
        conditions: [],
        days: ["EVERY SECOND FRIDAY OF THE MONTH"],
      }),
    ).toBe(true);
  });

  it("rejects every-weekday schedule", () => {
    expect(
      isNthWeekdayOfMonthMatch({
        title: "Happy Hour",
        details: ["Every Tuesday 4PM - 6PM"],
        conditions: [],
        days: ["Tuesday"],
      }),
    ).toBe(false);
  });

  it("rejects plain Tuesday schedule", () => {
    expect(
      isNthWeekdayOfMonthMatch({
        title: "Taco Tuesday",
        details: ["$5 tacos"],
        conditions: [],
        days: ["EVERY TUES"],
      }),
    ).toBe(false);
  });

  it("rejects normal weekly happy hour", () => {
    expect(
      isNthWeekdayOfMonthMatch({
        title: "Happy Hour",
        details: ["$8 wines", "HAPPY HOUR TUES - THURS 4PM - 6PM"],
        conditions: [],
        days: ["Tuesday", "Wednesday", "Thursday"],
      }),
    ).toBe(false);
  });
});
