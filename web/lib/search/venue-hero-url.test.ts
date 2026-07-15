import { describe, expect, it } from "vitest";
import { venueHeroThumbUrl } from "./venue-hero-url";

describe("venueHeroThumbUrl", () => {
  it("returns null for empty values", () => {
    expect(venueHeroThumbUrl(null)).toBeNull();
    expect(venueHeroThumbUrl(undefined)).toBeNull();
    expect(venueHeroThumbUrl("")).toBeNull();
    expect(venueHeroThumbUrl("   ")).toBeNull();
  });

  it("rewrites CDN full hero URLs to thumb", () => {
    expect(
      venueHeroThumbUrl("https://images.duskroute.com/venues/42.jpg"),
    ).toBe("https://images.duskroute.com/venues/42-thumb.jpg");
    expect(
      venueHeroThumbUrl("https://images.duskroute.com/venues/7.jpeg"),
    ).toBe("https://images.duskroute.com/venues/7-thumb.jpg");
  });

  it("leaves already-thumb CDN URLs unchanged", () => {
    expect(
      venueHeroThumbUrl("https://images.duskroute.com/venues/42-thumb.jpg"),
    ).toBe("https://images.duskroute.com/venues/42-thumb.jpg");
  });

  it("leaves non-CDN / source URLs unchanged", () => {
    const source = "https://example.com/photos/bar-front.jpg";
    expect(venueHeroThumbUrl(source)).toBe(source);
  });
});
