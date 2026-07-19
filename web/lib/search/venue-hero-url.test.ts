import { describe, expect, it } from "vitest";
import { suburbHeroThumbUrl, venueHeroThumbUrl } from "./venue-hero-url";

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

describe("suburbHeroThumbUrl", () => {
  it("returns null for empty values", () => {
    expect(suburbHeroThumbUrl(null)).toBeNull();
    expect(suburbHeroThumbUrl(undefined)).toBeNull();
    expect(suburbHeroThumbUrl("")).toBeNull();
    expect(suburbHeroThumbUrl("   ")).toBeNull();
  });

  it("rewrites CDN full hero URLs to thumb", () => {
    expect(
      suburbHeroThumbUrl("https://images.duskroute.com/suburbs/42.jpg"),
    ).toBe("https://images.duskroute.com/suburbs/42-thumb.jpg");
    expect(
      suburbHeroThumbUrl("https://images.duskroute.com/suburbs/7.jpeg"),
    ).toBe("https://images.duskroute.com/suburbs/7-thumb.jpg");
  });

  it("leaves already-thumb CDN URLs unchanged", () => {
    expect(
      suburbHeroThumbUrl("https://images.duskroute.com/suburbs/42-thumb.jpg"),
    ).toBe("https://images.duskroute.com/suburbs/42-thumb.jpg");
  });

  it("leaves non-CDN / source URLs unchanged", () => {
    const source = "https://example.com/photos/suburb-street.jpg";
    expect(suburbHeroThumbUrl(source)).toBe(source);
  });
});
