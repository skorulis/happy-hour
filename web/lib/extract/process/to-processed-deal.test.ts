import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { toProcessedDeal } from "@/lib/extract/process/to-processed-deal";
import { processExtractedDeals } from "@/lib/extract/process";
import { parseDealExtractionPayload } from "@/lib/extract/openrouter";
import type {
  ExtractDealsSource,
  ExtractedDeal,
} from "@/lib/extract/types";

// Ported from DealScraper/DealScraperTests/VenueDealPersistenceMapperTests.swift

function raw(o: Partial<ExtractedDeal>): ExtractedDeal {
  return {
    title: o.title ?? "",
    details: o.details ?? [],
    conditions: o.conditions ?? [],
    days: o.days ?? [],
    times: o.times ?? [],
    promotionDates: o.promotionDates ?? null,
  };
}

// Swift `VenueDealSourceMaterial.fixture()` default is a webpage source.
const webpageSource: ExtractDealsSource = {
  type: "webpage",
  url: "https://example.com/specials",
  sourceURL: "https://example.com/specials",
};

function loadFixture(name: string): ExtractedDeal[] {
  const path = join(
    process.cwd(),
    "lib",
    "extract",
    "process",
    "fixtures",
    `${name}.json`,
  );
  return parseDealExtractionPayload(readFileSync(path, "utf8")).deals;
}

describe("toProcessedDeal", () => {
  it("maps raw deal to deal and schedules", () => {
    const source: ExtractDealsSource = {
      type: "image",
      url: "https://example.com/poster.jpg",
      sourceURL: "https://example.com/specials",
    };
    const deal = toProcessedDeal(
      raw({
        title: "Happy Hour",
        details: ["$8 wines"],
        conditions: ["Dine-in only"],
        days: ["Friday"],
        times: ["4PM - 6PM"],
      }),
      source,
    );
    expect(deal).not.toBeNull();
    expect(deal!.title).toBe("Happy Hour");
    expect(deal!.details).toBe("$8 Wines");
    expect(deal!.conditions).toBe("Dine-in only");
    expect(deal!.creativeURL).toBe("https://example.com/poster.jpg");
    expect(deal!.sourceURL).toBe("https://example.com/specials");
    expect(deal!.schedules.length).toBeGreaterThan(0);
    expect(deal!.schedules.some((s) => s.dayOfWeek === 6)).toBe(true);
  });

  it("auto-rejects deal with same-day start and end dates", () => {
    const deal = toProcessedDeal(
      raw({
        title: "Gift Card Sale",
        details: ["25% off all gift cards"],
        conditions: [],
        days: [],
        times: ["all day"],
        promotionDates: ["14 November 2025"],
      }),
      webpageSource,
    );
    expect(deal).not.toBeNull();
    expect(deal!.status).toBe("rejected");
  });

  it("auto-rejects nth-weekday-of-month deal", () => {
    const deal = toProcessedDeal(
      raw({
        title: "Steak Night",
        details: ["$22 steaks", "First Tuesday of each Month"],
        conditions: [],
        days: ["First Tuesday of each Month"],
        times: ["all day"],
      }),
      webpageSource,
    );
    expect(deal).not.toBeNull();
    expect(deal!.status).toBe("rejected");
  });

  it("expands every day across the week", () => {
    const deal = toProcessedDeal(
      raw({
        title: "Daily Special",
        details: ["$5 beers"],
        days: ["every day"],
        times: ["all day"],
      }),
      webpageSource,
    );
    expect(deal).not.toBeNull();
    expect(deal!.schedules).toHaveLength(7);
  });

  it("maps multiple sources with correct URLs", () => {
    const firstSource: ExtractDealsSource = {
      type: "image",
      url: "https://example.com/poster-a.jpg",
      sourceURL: "https://example.com/specials-a",
    };
    const secondSource: ExtractDealsSource = {
      type: "image",
      url: "https://example.com/poster-b.jpg",
      sourceURL: "https://example.com/specials-b",
    };
    const mapped = [
      ...processExtractedDeals(
        [
          raw({
            title: "Deal A",
            details: ["$5 beers"],
            days: ["Monday"],
            times: ["all day"],
          }),
        ],
        firstSource,
      ),
      ...processExtractedDeals(
        [
          raw({
            title: "Deal B",
            details: ["$6 wines"],
            days: ["Tuesday"],
            times: ["all day"],
          }),
        ],
        secondSource,
      ),
    ];
    expect(mapped).toHaveLength(2);
    expect(
      mapped.some(
        (d) =>
          d.title === "Deal A" &&
          d.creativeURL === "https://example.com/poster-a.jpg",
      ),
    ).toBe(true);
    expect(
      mapped.some(
        (d) =>
          d.title === "Deal B" &&
          d.creativeURL === "https://example.com/poster-b.jpg",
      ),
    ).toBe(true);
    expect(
      mapped.some(
        (d) =>
          d.title === "Deal A" &&
          d.sourceURL === "https://example.com/specials-a",
      ),
    ).toBe(true);
    expect(
      mapped.some(
        (d) =>
          d.title === "Deal B" &&
          d.sourceURL === "https://example.com/specials-b",
      ),
    ).toBe(true);
  });

  it("maps PDF creative URL", () => {
    const source: ExtractDealsSource = {
      type: "pdf",
      url: "https://example.com/menu.pdf",
      sourceURL: "https://example.com/specials",
    };
    const deal = toProcessedDeal(
      raw({
        title: "Happy Hour",
        details: ["$8 wines"],
        days: ["Friday"],
        times: ["4PM - 6PM"],
      }),
      source,
    );
    expect(deal).not.toBeNull();
    expect(deal!.creativeURL).toBe("https://example.com/menu.pdf");
  });

  it("maps happy hour with split every-weekday days", () => {
    const json =
      '{"deals":[{"conditions":["* SELECTED RANGE OF BEER & WINE"],"times":["4PM-6PM"],"details":["BEERS","$7-"],"days":["EVERY","WEEKDAY"],"title":"HAPPY HOUR"}]}';
    const deals = processExtractedDeals(
      parseDealExtractionPayload(json).deals,
      webpageSource,
    );
    expect(deals).toHaveLength(1);
    const deal = deals[0]!;
    expect(deal.title).toBe("Happy Hour");
    expect(deal.details).toBe("Beers\n$7-");
    expect(deal.conditions).toBe("SELECTED RANGE OF BEER & WINE");
    expect(deal.schedules).toHaveLength(5);
    expect(
      deal.schedules.every(
        (s) => s.startMinute === 16 * 60 && s.endMinute === 18 * 60,
      ),
    ).toBe(true);
    expect(new Set(deal.schedules.map((s) => s.dayOfWeek))).toEqual(
      new Set([2, 3, 4, 5, 6]),
    );
  });

  it("maps Glebe steak-night fixture (ported source meal-time behavior)", () => {
    // NOTE: the Swift test asserts startMinute == 0 / endMinute == 1440, but the
    // Swift source applies the dinner-start meal adjustment (title contains
    // "Night"), shifting an all-day range to 17:00. We assert the ported source
    // behavior.
    const deals = processExtractedDeals(
      loadFixture("glebe-steak-nights"),
      webpageSource,
    );
    expect(deals).toHaveLength(1);
    const deal = deals[0]!;
    expect(deal.title).toBe("$22 Steak Night");
    expect(deal.details).toBe("Raise\nThe\nSteaks");
    expect(deal.conditions).toBe(
      "only available with bar service in our public bar, beer garden and nude",
    );
    expect(deal.schedules).toHaveLength(1);
    const schedule = deal.schedules[0]!;
    expect(schedule.dayOfWeek).toBe(2);
    expect(schedule.startMinute).toBe(17 * 60);
    expect(schedule.endMinute).toBe(1440);
  });

  it("adjusts dinner deal start from midnight to 5PM", () => {
    const deal = toProcessedDeal(
      raw({
        title: "Dinner Special",
        details: ["$25 mains"],
        days: ["Friday"],
        times: ["till 10pm"],
      }),
      webpageSource,
    )!;
    expect(deal.schedules).toHaveLength(1);
    expect(deal.schedules[0]!.startMinute).toBe(17 * 60);
    expect(deal.schedules[0]!.endMinute).toBe(22 * 60);
  });

  it("adjusts evening deal start from midnight to 5PM", () => {
    const deal = toProcessedDeal(
      raw({
        title: "Evening Special",
        details: ["$25 mains"],
        days: ["Friday"],
        times: ["till 10pm"],
      }),
      webpageSource,
    )!;
    expect(deal.schedules[0]!.startMinute).toBe(17 * 60);
    expect(deal.schedules[0]!.endMinute).toBe(22 * 60);
  });

  it("adjusts lunch deal from midnight-to-midnight to 12PM-2PM", () => {
    const deal = toProcessedDeal(
      raw({
        title: "Lunch Special",
        details: ["$15 burgers"],
        days: ["Monday"],
        times: ["all day"],
      }),
      webpageSource,
    )!;
    expect(deal.schedules[0]!.startMinute).toBe(12 * 60);
    expect(deal.schedules[0]!.endMinute).toBe(14 * 60);
  });

  it("does not adjust lunch deal with explicit times", () => {
    const deal = toProcessedDeal(
      raw({
        title: "Lunch Special",
        details: ["$15 burgers"],
        days: ["Monday"],
        times: ["till 10pm"],
      }),
      webpageSource,
    )!;
    expect(deal.schedules[0]!.startMinute).toBe(0);
    expect(deal.schedules[0]!.endMinute).toBe(22 * 60);
  });

  it("does not adjust dinner start when lunch is mentioned", () => {
    const deal = toProcessedDeal(
      raw({
        title: "Lunch and Dinner",
        details: ["Available all evening"],
        days: ["Friday"],
        times: ["till 10pm"],
      }),
      webpageSource,
    )!;
    expect(deal.schedules[0]!.startMinute).toBe(0);
    expect(deal.schedules[0]!.endMinute).toBe(22 * 60);
  });

  it("does not adjust non-dinner deal start from midnight", () => {
    const deal = toProcessedDeal(
      raw({
        title: "Happy Hour",
        details: ["$8 wines"],
        days: ["Friday"],
        times: ["till 10pm"],
      }),
      webpageSource,
    )!;
    expect(deal.schedules[0]!.startMinute).toBe(0);
    expect(deal.schedules[0]!.endMinute).toBe(22 * 60);
  });

  it("maps calendar-only deal from promotion dates", () => {
    const deal = toProcessedDeal(
      raw({
        title: "Gift Card Sale \u2013 25% Off",
        details: ["25% off all gift cards"],
        conditions: ["Enter code BLKFDAY at checkout to receive 25% off."],
        days: [],
        times: ["all day"],
        promotionDates: ["Friday, 14 November \u2013 Monday, 1 December 2025"],
      }),
      webpageSource,
    )!;
    expect(deal.schedules).toHaveLength(0);
    expect(deal.startDate).toBe("2025-11-14");
    expect(deal.endDate).toBe("2025-12-01");
    expect(deal.status).toBe("new");
  });
});

describe("processExtractedDeals", () => {
  it("maps and filters dropped deals", () => {
    const deals = processExtractedDeals(
      [
        raw({
          title: "Happy Hour",
          details: ["$8 wines"],
          days: ["Friday"],
          times: ["4PM - 6PM"],
        }),
        raw({ title: "   ", details: [], days: [], times: [] }),
      ],
      webpageSource,
    );
    expect(deals).toHaveLength(1);
    expect(deals[0]!.title).toBe("Happy Hour");
  });
});
