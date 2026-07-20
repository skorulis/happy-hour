import { describe, expect, it } from "vitest";
import {
  parseDealExtractionPayload,
  stripMarkdownCodeFence,
} from "@/lib/extract/openrouter";
import { ValidationError, parseExtractDealsRequest } from "@/lib/extract/validate";

describe("stripMarkdownCodeFence", () => {
  it("strips fenced json", () => {
    expect(stripMarkdownCodeFence('```json\n{"deals":[]}\n```')).toBe(
      '{"deals":[]}',
    );
  });
});

describe("parseDealExtractionPayload", () => {
  it("parses object payload", () => {
    const result = parseDealExtractionPayload(
      JSON.stringify({
        deals: [
          {
            title: "HAPPY HOUR",
            details: ["$8 wines"],
            conditions: [],
            days: ["FRI"],
            times: ["4-6"],
            promotionDates: null,
          },
        ],
      }),
    );
    expect(result.deals).toHaveLength(1);
    expect(result.deals[0]?.title).toBe("HAPPY HOUR");
  });

  it("parses bare array and string fields", () => {
    const result = parseDealExtractionPayload(
      JSON.stringify([
        {
          title: "TACOS",
          details: "$2 tacos",
          days: "TUESDAY",
          times: "all day",
        },
      ]),
    );
    expect(result.deals[0]?.details).toEqual(["$2 tacos"]);
    expect(result.deals[0]?.days).toEqual(["TUESDAY"]);
    expect(result.deals[0]?.conditions).toEqual([]);
  });
});

describe("parseExtractDealsRequest", () => {
  it("accepts image base64 source", () => {
    const parsed = parseExtractDealsRequest({
      venueName: "The Local",
      source: {
        type: "image",
        url: "poster.png",
        imageBase64: "abc",
        mimeType: "image/png",
      },
    });
    expect(parsed.venueName).toBe("The Local");
    expect(parsed.source.imageBase64).toBe("abc");
  });

  it("rejects image without content", () => {
    expect(() =>
      parseExtractDealsRequest({
        venueName: "The Local",
        source: { type: "image", url: "poster.png" },
      }),
    ).toThrow(ValidationError);
  });
});
