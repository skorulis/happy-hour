import { describe, expect, it } from "vitest";
import type { VenueListResult } from "@/lib/search/queries";
import { selectVenuesWithoutApplicableDeals } from "./venues-without-applicable-deals";

function venue(
  overrides: Partial<VenueListResult> & Pick<VenueListResult, "id" | "name">,
): VenueListResult {
  return {
    suburbName: "Surry Hills",
    lat: -33.88,
    lng: 151.21,
    websiteUri: null,
    heroImage: null,
    formattedAddress: null,
    ...overrides,
  };
}

describe("selectVenuesWithoutApplicableDeals", () => {
  it("includes venues with zero matching deals", () => {
    const suburbVenues = [
      venue({ id: 1, name: "No Deals Bar" }),
      venue({ id: 2, name: "Happy Hour Pub" }),
    ];

    expect(
      selectVenuesWithoutApplicableDeals(suburbVenues, [2]).map((v) => v.id),
    ).toEqual([1]);
  });

  it("includes venues whose deals miss the current filters", () => {
    // Primary search only returned venue 2 (e.g. Monday filter);
    // venue 1 has Tuesday-only deals and should appear in the complement.
    const suburbVenues = [
      venue({ id: 1, name: "Tuesday Only" }),
      venue({ id: 2, name: "Monday Match" }),
      venue({ id: 3, name: "Also No Match" }),
    ];

    expect(
      selectVenuesWithoutApplicableDeals(suburbVenues, [2]).map((v) => v.name),
    ).toEqual(["Tuesday Only", "Also No Match"]);
  });

  it("excludes venues when a matching deal exists", () => {
    const suburbVenues = [
      venue({ id: 1, name: "Matched" }),
      venue({ id: 2, name: "Also Matched" }),
    ];

    expect(
      selectVenuesWithoutApplicableDeals(suburbVenues, [1, 2]),
    ).toEqual([]);
  });

  it("only considers venues from the suburb list (scoping)", () => {
    const suburbVenues = [venue({ id: 10, name: "In Suburb" })];
    // Nearby venue 99 matched deals but is not in the suburb list.
    expect(
      selectVenuesWithoutApplicableDeals(suburbVenues, [99]).map((v) => v.id),
    ).toEqual([10]);
  });

  it("returns all suburb venues when nothing matched", () => {
    const suburbVenues = [
      venue({ id: 1, name: "A" }),
      venue({ id: 2, name: "B" }),
    ];

    expect(
      selectVenuesWithoutApplicableDeals(suburbVenues, []).map((v) => v.id),
    ).toEqual([1, 2]);
  });
});
