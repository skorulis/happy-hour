import { describe, expect, it } from "vitest";
import {
  formatDealText,
  formatDetailsText,
  validateFormatDealTextRequest,
} from "./format-deal-text";

describe("validateFormatDealTextRequest", () => {
  it("accepts title only", () => {
    expect(validateFormatDealTextRequest({ title: "HAPPY HOUR" })).toEqual({
      ok: true,
      value: { title: "HAPPY HOUR" },
    });
  });

  it("accepts details only", () => {
    expect(
      validateFormatDealTextRequest({ details: "$8 SCHOONERS" }),
    ).toEqual({
      ok: true,
      value: { details: "$8 SCHOONERS" },
    });
  });

  it("rejects missing fields", () => {
    expect(validateFormatDealTextRequest({})).toEqual({
      ok: false,
      error: "Missing title or details",
    });
  });

  it("rejects invalid field types", () => {
    expect(validateFormatDealTextRequest({ title: 14 })).toEqual({
      ok: false,
      error: "Invalid title",
    });
  });
});

describe("formatDealText", () => {
  it("title-cases titles", () => {
    expect(formatDealText({ title: "HAPPY HOUR" })).toEqual({
      title: "Happy Hour",
    });
  });

  it("leaves price-only titles unchanged", () => {
    expect(formatDealText({ title: "$8" })).toEqual({
      title: "$8",
    });
  });

  it("sentence-cases detail lines", () => {
    expect(formatDealText({ details: "$8 SCHOONERS\nALL DAY" })).toEqual({
      details: "$8 Schooners\nAll day",
    });
  });

  it("formats requested fields independently", () => {
    expect(
      formatDealText({
        title: "CHEESEBURGER TUESDAYS",
        details: "TEN DOLLAR BURGERS",
      }),
    ).toEqual({
      title: "Cheeseburger Tuesdays",
      details: "Ten dollar burgers",
    });
  });
});

describe("formatDetailsText", () => {
  it("returns empty string unchanged", () => {
    expect(formatDetailsText("")).toBe("");
  });
});
