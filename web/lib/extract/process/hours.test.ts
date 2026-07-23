import { describe, expect, it } from "vitest";
import {
  adjustedEndMinute,
  parseDealHours,
  toMinutes,
} from "@/lib/extract/process/hours";
import type { DealHours } from "@/lib/extract/process/types";

// Ported from DealScraper/DealScraperTests/Model/DealHoursTests.swift

const from = (minutes: number): DealHours => ({ kind: "from", minutes });
const between = (start: number, end: number): DealHours => ({
  kind: "between",
  start,
  end,
});
const allDay: DealHours = { kind: "allDay" };

describe("toMinutes", () => {
  it("parses explicit PM time", () => {
    expect(toMinutes("4 PM")).toBe(960);
    expect(toMinutes("4pm")).toBe(960);
    expect(toMinutes("  4 pm  ")).toBe(960);
  });

  it("parses explicit AM time", () => {
    expect(toMinutes("7 AM")).toBe(420);
    expect(toMinutes("9am")).toBe(540);
  });

  it("parses time with minutes", () => {
    expect(toMinutes("4:30 PM")).toBe(990);
    expect(toMinutes("7:15am")).toBe(435);
    expect(toMinutes("6.30pm")).toBe(1110);
    expect(toMinutes("4.30 PM")).toBe(990);
    expect(toMinutes("630pm")).toBe(18 * 60 + 30);
  });

  it("guesses AM when only AM fits in range", () => {
    expect(toMinutes("11:30")).toBe(690);
    expect(toMinutes("10:00")).toBe(600);
    expect(toMinutes("9:30")).toBe(570);
  });

  it("guesses PM when only PM fits in range", () => {
    expect(toMinutes("4:00")).toBe(960);
    expect(toMinutes("1:30")).toBe(810);
  });

  it("guesses noon for ambiguous midday", () => {
    expect(toMinutes("12:00")).toBe(720);
  });

  it("parses named times", () => {
    expect(toMinutes("NOON")).toBe(12 * 60);
    expect(toMinutes("midnight")).toBe(0);
  });

  it("prefers PM when both AM and PM fit in range", () => {
    expect(toMinutes("7:00")).toBe(1140);
    expect(toMinutes("8:30")).toBe(1230);
  });

  it("returns null for unparseable input", () => {
    expect(toMinutes("not a time")).toBeNull();
    expect(toMinutes("")).toBeNull();
    expect(toMinutes("25:00")).toBeNull();
    expect(toMinutes("4:99")).toBeNull();
  });

  it("returns explicit time even when outside guess range", () => {
    expect(toMinutes("11:30 PM")).toBe(1410);
    expect(toMinutes("3:00 AM")).toBe(180);
  });
});

describe("parseDealHours", () => {
  it("parses noon time range", () => {
    expect(parseDealHours("NOON - 4PM")).toEqual(between(12 * 60, 16 * 60));
  });

  it("parses single time", () => {
    expect(parseDealHours("4 PM")).toEqual(from(960));
    expect(parseDealHours("11:30")).toEqual(from(690));
  });

  it("parses time range", () => {
    expect(parseDealHours("4 PM - 6 PM")).toEqual(between(960, 1080));
    expect(parseDealHours("4 PM-6 PM")).toEqual(between(960, 1080));
    expect(parseDealHours("4 PM to 6 PM")).toEqual(between(960, 1080));
    expect(parseDealHours("5pm-630pm")).toEqual(
      between(17 * 60, 18 * 60 + 30),
    );
  });

  it("parses all day", () => {
    expect(parseDealHours("all day")).toEqual(allDay);
    expect(parseDealHours("ALL DAY")).toEqual(allDay);
    expect(parseDealHours("all-day")).toEqual(allDay);
  });

  it("parses lunch as default midday range", () => {
    expect(parseDealHours("lunch")).toEqual(between(12 * 60, 14 * 60));
    expect(parseDealHours("LUNCH")).toEqual(between(12 * 60, 14 * 60));
  });

  it("parses open-to-end time range", () => {
    expect(parseDealHours("Open - 6pm")).toEqual(between(0, 18 * 60));
    expect(parseDealHours("Open-6pm")).toEqual(between(0, 18 * 60));
    expect(parseDealHours("opening to 6 PM")).toEqual(between(0, 18 * 60));
    expect(parseDealHours("Open – 6:00pm")).toEqual(between(0, 18 * 60));
  });

  it("parses en-dash and em-dash time ranges", () => {
    expect(parseDealHours("5PM – 8PM")).toEqual(between(17 * 60, 20 * 60));
    expect(parseDealHours("5PM — 8PM")).toEqual(between(17 * 60, 20 * 60));
    expect(parseDealHours("5PM\u20148PM")).toEqual(between(17 * 60, 20 * 60));
  });

  it("returns null for unparseable input", () => {
    expect(parseDealHours("")).toBeNull();
    expect(parseDealHours("not a time")).toBeNull();
  });

  it("parses from prefix (fromString equivalent)", () => {
    expect(parseDealHours("from 11AM")).toEqual(from(660));
    expect(parseDealHours("FROM 11:30")).toEqual(from(690));
  });

  it("parses time range (fromString equivalent)", () => {
    expect(parseDealHours("4PM - 6PM")).toEqual(between(960, 1080));
    expect(parseDealHours("4 PM - 6 PM")).toEqual(between(960, 1080));
    expect(parseDealHours("FROM 4-6PM")).toEqual(between(960, 1080));
  });

  it("parses from-prefixed compact time range", () => {
    expect(parseDealHours("FROM 4-6PM")).toEqual(between(960, 1080));
    expect(parseDealHours("from 4-6pm")).toEqual(between(960, 1080));
  });

  it("returns null for unparseable input (fromString equivalent)", () => {
    expect(parseDealHours("")).toBeNull();
    expect(parseDealHours("from")).toBeNull();
    expect(parseDealHours("not a time")).toBeNull();
  });

  it("parses overnight time range before ten AM", () => {
    expect(parseDealHours("10PM - 2AM")).toEqual(between(22 * 60, 26 * 60));
    expect(parseDealHours("4pm-2am")).toEqual(between(16 * 60, 26 * 60));
  });

  it("does not treat midnight end of day as overnight", () => {
    expect(parseDealHours("10PM - midnight")).toEqual(
      between(22 * 60, 24 * 60),
    );
  });

  it("does not treat same-day morning range as overnight", () => {
    expect(parseDealHours("1AM - 2AM")).toEqual(between(60, 120));
  });
});

describe("adjustedEndMinute", () => {
  it("extends early morning end into next day", () => {
    expect(adjustedEndMinute(22 * 60, 2 * 60)).toBe(26 * 60);
    expect(adjustedEndMinute(16 * 60, 18 * 60)).toBe(18 * 60);
  });
});
