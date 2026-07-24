import { describe, expect, it } from "vitest";
import {
  trimOnce,
  trimUntilStable,
} from "@/lib/extract/process/title-trimmer";

// Ported from DealScraper/DealScraperTests/Service/DealTitleTrimmerTests.swift

describe("trimOnce", () => {
  it("leaves bare title untouched", () => {
    expect(trimOnce("Happy Hour")).toBe("Happy Hour");
    expect(trimOnce("$8 Schooners")).toBe("$8 Schooners");
  });

  it("trims whitespace", () => {
    expect(trimOnce("  Happy Hour  ")).toBe("Happy Hour");
    expect(trimOnce("\nSteak Night\n")).toBe("Steak Night");
  });

  it("returns empty for whitespace-only input", () => {
    expect(trimOnce("   ")).toBe("");
    expect(trimOnce("\n")).toBe("");
  });

  it("strips cleanLine characters", () => {
    expect(trimOnce("*Happy Hour*")).toBe("Happy Hour");
    expect(trimOnce("_Steak Night_")).toBe("Steak Night");
    expect(trimOnce("|Pizza Night|")).toBe("Pizza Night");
    expect(trimOnce("\u2019Happy Hour\u2019")).toBe("Happy Hour");
    expect(trimOnce("Happy Hour\u2019")).toBe("Happy Hour");
    expect(trimOnce("-Happy Hour-")).toBe("Happy Hour");
    expect(trimOnce("Happy Hour-")).toBe("Happy Hour");
    expect(trimOnce("Happy Hour,")).toBe("Happy Hour");
    expect(trimOnce(",Happy Hour,")).toBe("Happy Hour");
    expect(trimOnce("Happy Hour:")).toBe("Happy Hour");
    expect(trimOnce(":Happy Hour:")).toBe("Happy Hour");
    expect(trimOnce("&Happy Hour&")).toBe("Happy Hour");
    expect(trimOnce("Happy Hour&")).toBe("Happy Hour");
  });

  it("strips leading day word", () => {
    expect(trimOnce("TUESDAY Steak Night")).toBe("Steak Night");
    expect(trimOnce("Friday Happy Hour")).toBe("Happy Hour");
    expect(trimOnce("Monday: Burger Night")).toBe("Burger Night");
    expect(trimOnce("Monday : Burger Night")).toBe("Burger Night");
  });

  it("strips trailing day word", () => {
    expect(trimOnce("Night Trivia Tuesday")).toBe("Night Trivia");
    expect(trimOnce("Steak Night Thurs")).toBe("Steak Night");
  });

  it("keeps plural day words in title", () => {
    expect(trimOnce("Cheeseburger Tuesdays")).toBe("Cheeseburger Tuesdays");
  });

  it("strips single day-only title", () => {
    expect(trimOnce("Tuesday")).toBe("");
  });

  it("strips available-from suffix", () => {
    expect(trimOnce("Lunch Available From 12PM")).toBe("Lunch");
    expect(trimOnce("Happy Hour available from 5pm")).toBe("Happy Hour");
  });

  it("strips full time-range suffix", () => {
    expect(trimOnce("$19 Chicken Parmi 4PM - 6PM")).toBe("$19 Chicken Parmi");
    expect(trimOnce("Happy Hour 4PM to 6PM")).toBe("Happy Hour");
    expect(trimOnce("Happy Hour 4PM til 6PM")).toBe("Happy Hour");
    expect(trimOnce("Happy Hour 4PM till 6PM")).toBe("Happy Hour");
    expect(trimOnce("Happy Hour 4PM 'til 6PM")).toBe("Happy Hour");
    expect(trimOnce("Happy Hour 4PM until 6PM")).toBe("Happy Hour");
    expect(trimOnce("Happy Hour 4PM \u2013 6PM")).toBe("Happy Hour");
    expect(trimOnce("Happy Hour 4PM \u2014 6PM")).toBe("Happy Hour");
  });

  it("strips partial time-range suffix", () => {
    expect(trimOnce("$19 Chicken Parmi 4PM -")).toBe("$19 Chicken Parmi");
    expect(trimOnce("Happy Hour 4PM \u2013")).toBe("Happy Hour");
    expect(trimOnce("Happy Hour 4PM \u2014")).toBe("Happy Hour");
  });

  it("strips trailing time", () => {
    expect(trimOnce("Lunch From 12PM")).toBe("Lunch");
    expect(trimOnce("Night Trivia 6:30PM")).toBe("Night Trivia");
    expect(trimOnce("Happy Hour 430pm")).toBe("Happy Hour");
  });

  it("strips trailing from word after time removed", () => {
    expect(trimOnce("Bottle Shop Wines From $20")).toBe(
      "Bottle Shop Wines From $20",
    );
    expect(trimOnce("Lunch From")).toBe("Lunch");
  });

  it("strips trailing every word", () => {
    expect(trimOnce("Happy Hour Every")).toBe("Happy Hour");
    expect(trimOnce("Steak Night every")).toBe("Steak Night");
    expect(trimOnce("Every")).toBe("Every");
  });

  it("strips trailing orphan separator", () => {
    expect(trimOnce("Happy Hour -")).toBe("Happy Hour");
    expect(trimOnce("Happy Hour \u2013")).toBe("Happy Hour");
    expect(trimOnce("Happy Hour \u2014")).toBe("Happy Hour");
    expect(trimOnce("Happy Hour &")).toBe("Happy Hour");
  });

  it("keeps ampersand inside title", () => {
    expect(trimOnce("Food & Drink")).toBe("Food & Drink");
  });

  it("does not strip invalid trailing times", () => {
    expect(trimOnce("Happy Hour 25:00")).toBe("Happy Hour 25:00");
    expect(trimOnce("Happy Hour not a time")).toBe("Happy Hour not a time");
  });

  it("may need another pass when day follows removed time", () => {
    expect(trimOnce("Night Trivia Tuesday 6:30PM")).toBe(
      "Night Trivia Tuesday",
    );
    expect(trimUntilStable("Night Trivia Tuesday 6:30PM")).toBe(
      "Night Trivia",
    );
  });

  it("is idempotent after stable", () => {
    const samples = [
      "Happy Hour",
      "Steak Night",
      "Night Trivia",
      "$19 Chicken Parmi",
      "Cheeseburger Tuesdays",
    ];
    for (const sample of samples) {
      expect(trimOnce(sample)).toBe(sample);
    }
  });
});

describe("trimUntilStable", () => {
  it("strips day and time together", () => {
    expect(trimUntilStable("NIGHT TRIVIA TUESDAY 6:30PM")).toBe(
      "NIGHT TRIVIA",
    );
  });

  it("matches trimOnce for representative titles", () => {
    const samples = [
      "Happy Hour 4PM - 6PM",
      "TUESDAY HAPPY HOUR 4PM - 6PM",
      "Lunch Available From 12PM",
      "$19 CHICKEN PARMI 4PM -",
    ];
    for (const sample of samples) {
      expect(trimUntilStable(sample)).toBe(trimOnce(sample));
    }
  });

  it("is stable", () => {
    const samples = [
      "Happy Hour",
      "NIGHT TRIVIA TUESDAY 6:30PM",
      "FRIDAY LUNCH FROM 12PM",
    ];
    for (const sample of samples) {
      const trimmed = trimUntilStable(sample);
      expect(trimUntilStable(trimmed)).toBe(trimmed);
    }
  });
});
