import { describe, expect, it } from "vitest";
import { R2ConfigError, normalizePublicBaseUrl } from "@/lib/r2";

describe("normalizePublicBaseUrl", () => {
  it("accepts a clean CDN base URL", () => {
    expect(normalizePublicBaseUrl("https://images.duskroute.com")).toBe(
      "https://images.duskroute.com",
    );
    expect(normalizePublicBaseUrl("https://images.duskroute.com/")).toBe(
      "https://images.duskroute.com",
    );
  });

  it("rejects values that swallowed the next env line", () => {
    expect(() =>
      normalizePublicBaseUrl(
        "https://images.duskroute.comAMPLITUDE_API_KEY=secret",
      ),
    ).toThrow(R2ConfigError);
  });
});
