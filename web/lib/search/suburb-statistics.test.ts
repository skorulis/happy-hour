import { describe, expect, it } from "vitest";
import type { SuburbStatistics } from "@/lib/search/queries";
import { sortSuburbStatistics } from "./suburb-statistics";

function suburb(
  overrides: Partial<SuburbStatistics> & Pick<SuburbStatistics, "id" | "name">,
): SuburbStatistics {
  return {
    postcode: null,
    heroImage: null,
    dealCount: 0,
    venueCount: 0,
    sqkm: null,
    population: null,
    venuesPerSqkm: null,
    dealsPerSqkm: null,
    venuesPerThousand: null,
    dealsPerThousand: null,
    ...overrides,
  };
}

describe("sortSuburbStatistics", () => {
  it("sorts density view by deals per sqkm, missing area last", () => {
    const sorted = sortSuburbStatistics(
      [
        suburb({
          id: 1,
          name: "No Area",
          dealCount: 99,
          sqkm: null,
        }),
        suburb({
          id: 2,
          name: "Sparse",
          sqkm: 10,
          dealsPerSqkm: 1,
        }),
        suburb({
          id: 3,
          name: "Dense",
          sqkm: 2,
          dealsPerSqkm: 5,
        }),
      ],
      "density",
    );

    expect(sorted.map((row) => row.name)).toEqual([
      "Dense",
      "Sparse",
      "No Area",
    ]);
  });

  it("sorts population view by deals per thousand, missing population last", () => {
    const sorted = sortSuburbStatistics(
      [
        suburb({
          id: 1,
          name: "No Pop",
          dealCount: 99,
          population: null,
        }),
        suburb({
          id: 2,
          name: "Low",
          population: 1000,
          dealsPerThousand: 1,
        }),
        suburb({
          id: 3,
          name: "High",
          population: 500,
          dealsPerThousand: 4,
        }),
      ],
      "population",
    );

    expect(sorted.map((row) => row.name)).toEqual(["High", "Low", "No Pop"]);
  });
});
