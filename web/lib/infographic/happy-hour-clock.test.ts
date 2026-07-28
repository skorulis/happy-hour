import { describe, expect, it } from "vitest";
import {
  buildHappyHourClockGeometry,
  formatHourLabel,
  hourToClockAngleDeg,
  normalizeStartHourShares,
  pickPeakStartHour,
} from "@/lib/infographic/happy-hour-clock";

describe("formatHourLabel", () => {
  it("formats noon and midnight correctly", () => {
    expect(formatHourLabel(12)).toBe("12pm");
    expect(formatHourLabel(0)).toBe("12am");
    expect(formatHourLabel(17)).toBe("5pm");
  });
});

describe("hourToClockAngleDeg", () => {
  it("puts 12 at top and steps 30° clockwise", () => {
    expect(hourToClockAngleDeg(12)).toBe(0);
    expect(hourToClockAngleDeg(15)).toBe(90);
    expect(hourToClockAngleDeg(18)).toBe(180);
    expect(hourToClockAngleDeg(21)).toBe(270);
  });
});

describe("normalizeStartHourShares", () => {
  it("returns twelve noon→11pm slots with zero percents when empty", () => {
    const hours = normalizeStartHourShares([]);
    expect(hours).toHaveLength(12);
    expect(hours[0]?.hour).toBe(12);
    expect(hours[11]?.hour).toBe(23);
    expect(hours.every((row) => row.percent === 0 && row.count === 0)).toBe(
      true,
    );
  });

  it("ignores morning hours and sums to 100", () => {
    const hours = normalizeStartHourShares([
      { hour: 9, count: 50 },
      { hour: 17, count: 2 },
      { hour: 18, count: 1 },
    ]);
    expect(hours.reduce((sum, row) => sum + row.percent, 0)).toBe(100);
    expect(hours.find((row) => row.hour === 17)?.percent).toBe(67);
    expect(hours.find((row) => row.hour === 18)?.percent).toBe(33);
    expect(hours.every((row) => row.hour >= 12)).toBe(true);
  });

  it("gives 100% to a single hour", () => {
    const hours = normalizeStartHourShares([{ hour: 17, count: 40 }]);
    expect(hours.find((row) => row.hour === 17)?.percent).toBe(100);
  });
});

describe("pickPeakStartHour", () => {
  it("picks the busiest hour in the noon→11pm window", () => {
    expect(
      pickPeakStartHour([
        { hour: 9, count: 99 },
        { hour: 17, count: 12 },
        { hour: 18, count: 20 },
      ]),
    ).toEqual({ hour: 18, count: 20 });
  });

  it("returns null when only morning hours exist", () => {
    expect(pickPeakStartHour([{ hour: 9, count: 5 }])).toBeNull();
  });
});

describe("buildHappyHourClockGeometry", () => {
  it("builds wedges for hours with counts without a hand", () => {
    const hours = normalizeStartHourShares([
      { hour: 16, count: 5 },
      { hour: 17, count: 20 },
      { hour: 18, count: 10 },
    ]);
    const geometry = buildHappyHourClockGeometry(hours, 17);
    expect(geometry.wedges).toHaveLength(3);
    expect(geometry.wedges.every((wedge) => wedge.pathD.includes("Z"))).toBe(
      true,
    );
    expect(geometry.peakHour).toBe(17);
    expect(geometry.ticks.length).toBeGreaterThan(0);
  });

  it("returns no wedges when all counts are zero", () => {
    const hours = normalizeStartHourShares([]);
    const geometry = buildHappyHourClockGeometry(hours, null);
    expect(geometry.wedges).toHaveLength(0);
  });
});
