import { describe, expect, it } from "vitest";
import { parseTimes, timesInText } from "@/lib/extract/process/time-parser";
import type { DealHours } from "@/lib/extract/process/types";

// Ported from DealScraper/DealScraperTests/DealTimeParserTests.swift

const from = (minutes: number): DealHours => ({ kind: "from", minutes });
const between = (start: number, end: number): DealHours => ({
  kind: "between",
  start,
  end,
});
const allDay: DealHours = { kind: "allDay" };

describe("parseTimes", () => {
  it("parses from-prefixed compact time range", () => {
    expect(parseTimes(["FROM 4-6PM"])).toEqual([between(16 * 60, 18 * 60)]);
  });

  it("parses compact time range with trailing punctuation", () => {
    expect(parseTimes(["2-4pm!"])).toEqual([between(14 * 60, 16 * 60)]);
  });

  it("parses till time as until end of range", () => {
    expect(parseTimes(["till 10pm"])).toEqual([between(0, 22 * 60)]);
  });

  it("parses from-till time range", () => {
    expect(parseTimes(["from 4pm till 10pm"])).toEqual([
      between(16 * 60, 22 * 60),
    ]);
  });

  it("parses available-from time range", () => {
    expect(parseTimes(["Available from 11:30am \u20133pm"])).toEqual([
      between(11 * 60 + 30, 15 * 60),
    ]);
  });

  it("parses available time range", () => {
    expect(parseTimes(["AVAILABLE 6:30\u20138:30PM"])).toEqual([
      between(18 * 60 + 30, 20 * 60 + 30),
    ]);
  });

  it("parses start-till-end time range", () => {
    expect(parseTimes(["3PM 'TIL 6PM"])).toEqual([between(15 * 60, 18 * 60)]);
  });

  it("parses PM-till-PM time range", () => {
    expect(parseTimes(["4pm 'til 6pm"])).toEqual([between(16 * 60, 18 * 60)]);
    expect(parseTimes(["4pm \u2019til 6pm"])).toEqual([
      between(16 * 60, 18 * 60),
    ]);
    expect(parseTimes(["6pm til' 10pm"])).toEqual([
      between(18 * 60, 22 * 60),
    ]);
  });

  it("parses bare-hour-till-PM time range", () => {
    expect(parseTimes(["12 'TIL 3PM"])).toEqual([between(12 * 60, 15 * 60)]);
    expect(parseTimes(["12 \u2019TIL 3PM"])).toEqual([
      between(12 * 60, 15 * 60),
    ]);
  });

  it("parses all-day tokens", () => {
    expect(parseTimes(["all day"])).toEqual([allDay]);
    expect(parseTimes(["ALL DAY", "all-day"])).toEqual([allDay]);
  });

  it("parses lunch as default midday range", () => {
    expect(parseTimes(["LUNCH"])).toEqual([between(12 * 60, 14 * 60)]);
    expect(parseTimes(["lunch"])).toEqual([between(12 * 60, 14 * 60)]);
  });

  it("parses lunch meal period when mixed with day range", () => {
    expect(parseTimes(["MON TO FRI LUNCH"])).toEqual([
      between(12 * 60, 14 * 60),
    ]);
  });

  it("prefers explicit clock times over lunch meal period", () => {
    expect(parseTimes(["LUNCH 11AM-3PM"])).toEqual([
      between(11 * 60, 15 * 60),
    ]);
    expect(parseTimes(["LUNCH FROM 12PM"])).toEqual([from(12 * 60)]);
  });

  it("does not treat lunch-and-dinner as lunch meal period", () => {
    expect(parseTimes(["LUNCH AND DINNER"])).toEqual([]);
  });

  it("returns empty for missing times", () => {
    expect(parseTimes([])).toEqual([]);
  });

  it("parses parenthesized time range", () => {
    expect(parseTimes(["(11 AM - 2 PM )"])).toEqual([
      between(11 * 60, 14 * 60),
    ]);
  });

  it("parses noon time range", () => {
    expect(parseTimes(["NOON - 4PM"])).toEqual([between(12 * 60, 16 * 60)]);
  });

  it("parses start-between time range", () => {
    expect(parseTimes(["with a start between 12pm-3:15pm."])).toEqual([
      between(12 * 60, 15 * 60 + 15),
    ]);
  });

  it("parses between time range with optional start period", () => {
    expect(parseTimes(["BETWEEN 4 - 6.30PM"])).toEqual([
      between(16 * 60, 18 * 60 + 30),
    ]);
  });

  it("parses markdown bold wrapped time range", () => {
    expect(parseTimes(["**3PM\u20136PM**"])).toEqual([
      between(15 * 60, 18 * 60),
    ]);
  });

  it("parses em-dash time range", () => {
    expect(parseTimes(["5PM — 8PM"])).toEqual([between(17 * 60, 20 * 60)]);
    expect(parseTimes(["5PM\u20148PM"])).toEqual([between(17 * 60, 20 * 60)]);
  });

  it("parses markdown bold wrapped till-close time", () => {
    expect(parseTimes(["**9PM till close**"])).toEqual([from(21 * 60)]);
  });

  it("parses from and drawn-at split time range", () => {
    const expected = [between(17 * 60, 19 * 60 + 30)];
    expect(parseTimes(["FROM 5PM", "DRAWN AT 7:30PM"])).toEqual(expected);
    expect(parseTimes(["5pm-7:30pm"])).toEqual(expected);
  });

  it("parses from-drawn inline time range", () => {
    const expected = [between(16 * 60, 18 * 60)];
    expect(parseTimes(["20 TICKETS SOLD FROM 4PM DRAWN 6PM"])).toEqual(
      expected,
    );
    expect(parseTimes(["FROM 4PM DRAWN 6PM"])).toEqual(expected);
    expect(timesInText("20 TICKETS SOLD FROM 4PM DRAWN 6PM")).toEqual(
      expected,
    );
  });

  it("parses from and drawn split time range without at", () => {
    const expected = [between(17 * 60, 19 * 60 + 30)];
    expect(parseTimes(["FROM 5PM", "DRAWN 7:30PM"])).toEqual(expected);
  });

  it("parses on-sale-from and draws-from split time range", () => {
    const expected = [between(17 * 60, 18 * 60 + 30)];
    expect(parseTimes(["ON SALE FROM 5PM", "DRAWS FROM 6:30PM"])).toEqual(
      expected,
    );
    expect(parseTimes(["ON SALE FROM 5PM DRAWS FROM 6:30PM"])).toEqual(
      expected,
    );
  });

  it("parses sales and draws inline time range", () => {
    const expected = [between(17 * 60 + 30, 19 * 60 + 30)];
    expect(parseTimes(["SALES 5.30PM DRAWS 7.30PM"])).toEqual(expected);
    expect(timesInText("SALES 5.30PM DRAWS 7.30PM")).toEqual(expected);
  });

  it("parses multiple listed times as range", () => {
    expect(parseTimes(["3pm, 3:30pm & 4pm"])).toEqual([
      between(15 * 60, 16 * 60),
    ]);
  });

  it("parses overnight time range", () => {
    expect(parseTimes(["10PM - 2AM"])).toEqual([between(22 * 60, 26 * 60)]);
    expect(parseTimes(["from 4pm till 2am"])).toEqual([
      between(16 * 60, 26 * 60),
    ]);
  });

  it("parses time-label-prefixed range", () => {
    expect(parseTimes(["Time - 2pm-5pm"])).toEqual([
      between(14 * 60, 17 * 60),
    ]);
    expect(parseTimes(["Time: 2pm-5pm"])).toEqual([between(14 * 60, 17 * 60)]);
  });

  it("parses happy-hour-prefixed time range", () => {
    expect(parseTimes(["HAPPY HOUR 4-6PM"])).toEqual([
      between(16 * 60, 18 * 60),
    ]);
    expect(timesInText("HAPPY HOUR 4-6PM")).toEqual([
      between(16 * 60, 18 * 60),
    ]);
  });

  it("parses embedded time range with leading label", () => {
    expect(parseTimes(["BISTRO OPEN 5PM-8:30PM"])).toEqual([
      between(17 * 60, 20 * 60 + 30),
    ]);
    expect(timesInText("BISTRO OPEN 5PM-8:30PM")).toEqual([
      between(17 * 60, 20 * 60 + 30),
    ]);
  });

  it("parses dotted meridiem time range", () => {
    expect(parseTimes(["3 p.m. \u2013 6 p.m."])).toEqual([
      between(15 * 60, 18 * 60),
    ]);
  });

  it("parses hours-from-prefixed time range", () => {
    expect(parseTimes(["2 HRS FROM 12-5PM"])).toEqual([
      between(12 * 60, 17 * 60),
    ]);
  });

  it("parses bullet-wrapped to time range", () => {
    expect(parseTimes(["\u2022 5PM TO 10PM \u2022"])).toEqual([
      between(17 * 60, 22 * 60),
    ]);
  });

  it("parses OCR to-token time range", () => {
    expect(parseTimes(["5 T\u00ba 6PM"])).toEqual([between(17 * 60, 18 * 60)]);
  });

  it("parses arrive-at for start time as evening through midnight", () => {
    expect(parseTimes(["TIME: ARRIVE AT 6:00PM for 6:30PM START"])).toEqual([
      between(18 * 60, 24 * 60),
    ]);
  });

  it("parses rego-for-start as evening through midnight", () => {
    expect(parseTimes(["6PM REGO FOR 6:30PM START"])).toEqual([
      between(18 * 60, 24 * 60),
    ]);
  });

  it("parses hyphen-continued split time range", () => {
    expect(parseTimes(["7.30 pm", "-10.30 pm"])).toEqual([
      between(19 * 60 + 30, 22 * 60 + 30),
    ]);
  });

  it("drops a from-time covered by a range", () => {
    expect(parseTimes(["4-5pm", "5pm"])).toEqual([
      between(16 * 60, 17 * 60),
    ]);
  });
});

describe("timesInText", () => {
  it("extracts time range from supplement text", () => {
    const times = timesInText("TUES - THURS 4PM - 6PM / FRI 3PM - 5PM");
    expect(times.length).toBeGreaterThan(0);
  });
});
