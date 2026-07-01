import { describe, expect, it } from "vitest";
import { formatDistanceKm } from "./distance";

describe("formatDistanceKm", () => {
  it("formats sub-kilometre distances in metres", () => {
    expect(formatDistanceKm(0.45)).toBe("450 m");
    expect(formatDistanceKm(0.001)).toBe("1 m");
  });

  it("formats short kilometre distances with one decimal", () => {
    expect(formatDistanceKm(2.34)).toBe("2.3 km");
    expect(formatDistanceKm(9.99)).toBe("10.0 km");
  });

  it("formats longer distances as whole kilometres", () => {
    expect(formatDistanceKm(12.4)).toBe("12 km");
    expect(formatDistanceKm(25.6)).toBe("26 km");
  });
});
