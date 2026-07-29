import { describe, expect, it } from "vitest";
import {
  buildDensityBarRows,
  formatDensityBarValue,
} from "@/lib/infographic/density-bars";

describe("density-bars", () => {
  it("builds proportional rows with the leader at full width", () => {
    const rows = buildDensityBarRows([
      { name: "Surry Hills", postcode: "2010", value: 20, dealCount: 20 },
      { name: "Newtown", postcode: "2042", value: 10, dealCount: 15 },
    ]);

    expect(rows).toHaveLength(2);
    expect(rows[0]).toMatchObject({
      name: "Surry Hills",
      widthPercent: 100,
      isLeader: true,
    });
    expect(rows[1]).toMatchObject({
      name: "Newtown",
      widthPercent: 50,
      isLeader: false,
    });
  });

  it("formats density and deal values", () => {
    expect(formatDensityBarValue(12.34, "density")).toBe("12.3/km²");
    expect(formatDensityBarValue(1200, "deals")).toBe("1,200");
  });
});
