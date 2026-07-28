import {
  findMatchingProductsForDeals,
  type DealTextFields,
} from "@data/products";
import { HAPPY_HOUR_CLOCK_HOURS } from "@/lib/infographic/happy-hour-clock";
import type { RegionDayHourCount } from "@/lib/infographic/types";
import type { RegionDealScheduleMatchRow } from "@/lib/search/queries";
import {
  isAllDaySchedule,
  minutesWithinDay,
  WEEKDAY_UI_ORDER,
} from "@/lib/search/schedule";
import { appendFiltersToPath } from "@/lib/search/what-path";

export const HAPPY_HOUR_HEAT_HOURS = HAPPY_HOUR_CLOCK_HOURS;

/** Empty cells stay near the poster background. */
export const DAY_HOUR_HEAT_EMPTY_COLOR = "#1a2230";

/**
 * Dark amber ramp for cells with count > 0. Low values sit near-grey but
 * stay warm (not slate); peak stays bright gold.
 */
export const DAY_HOUR_HEAT_COLORS = [
  "#3d342c", // near-grey amber
  "#4a3728",
  "#5c3d22",
  "#6e4420",
  "#85531c",
  "#a05f14",
  "#c4740a",
  "#e09420",
  "#f0c060",
] as const;

export type DayHourHeatCell = {
  dayOfWeek: number;
  hour: number;
  count: number;
  /** 0–1 display intensity (sqrt-scaled vs max). */
  intensity: number;
  color: string;
  isPeak: boolean;
};

export type DayHourHeatGrid = {
  hours: readonly number[];
  days: readonly number[];
  cells: DayHourHeatCell[];
  peak: RegionDayHourCount | null;
  total: number;
};

export function dealMatchesHappyHour(deal: DealTextFields): boolean {
  return findMatchingProductsForDeals([deal]).some(
    (product) => product.name.toLowerCase() === "happy hour",
  );
}

/**
 * Hours a schedule covers on its listed day (before midnight), excluding
 * all-day rows. A 4–6pm window yields [16, 17].
 */
export function hoursCoveredOnScheduleDay(
  startMinute: number,
  endMinute: number,
): number[] {
  if (isAllDaySchedule(startMinute, endMinute)) {
    return [];
  }
  const start = minutesWithinDay(startMinute);
  const endExclusive = Math.min(Math.max(endMinute, start + 1), 1440);
  const startHour = Math.floor(start / 60);
  const lastHour = Math.floor((endExclusive - 1) / 60);
  const hours: number[] = [];
  for (let hour = startHour; hour <= lastHour && hour < 24; hour += 1) {
    hours.push(hour);
  }
  return hours;
}

/**
 * Soften linear drop-off so mid values stay visibly warm. Peak stays 1;
 * a cell at 25% of peak still lands around 0.5.
 */
export function heatDisplayIntensity(count: number, maxCount: number): number {
  if (count <= 0 || maxCount <= 0) {
    return 0;
  }
  return Math.sqrt(count / maxCount);
}

export function colorForHeatIntensity(intensity: number): string {
  if (intensity <= 0) {
    return DAY_HOUR_HEAT_EMPTY_COLOR;
  }
  const scaled = Math.min(1, intensity) * (DAY_HOUR_HEAT_COLORS.length - 1);
  const index = Math.min(
    DAY_HOUR_HEAT_COLORS.length - 1,
    Math.max(0, Math.round(scaled)),
  );
  return DAY_HOUR_HEAT_COLORS[index]!;
}

/**
 * Count (day × hour) coverage for deals that match the happy hour product.
 * Only noon→11pm hours are kept for the dial-aligned heat window.
 */
export function tallyHappyHourDayHourCounts(
  rows: RegionDealScheduleMatchRow[],
): RegionDayHourCount[] {
  const happyHourDealIds = new Set<number>();
  const seenDeals = new Map<number, DealTextFields>();

  for (const row of rows) {
    if (seenDeals.has(row.dealId)) continue;
    seenDeals.set(row.dealId, {
      title: row.title,
      details: row.details,
      conditions: row.conditions,
    });
  }

  for (const [dealId, deal] of seenDeals) {
    if (dealMatchesHappyHour(deal)) {
      happyHourDealIds.add(dealId);
    }
  }

  if (happyHourDealIds.size === 0) {
    return [];
  }

  const heatHours = new Set<number>(HAPPY_HOUR_HEAT_HOURS);
  const counts = new Map<string, RegionDayHourCount>();

  for (const row of rows) {
    if (!happyHourDealIds.has(row.dealId)) continue;
    for (const hour of hoursCoveredOnScheduleDay(
      row.startMinute,
      row.endMinute,
    )) {
      if (!heatHours.has(hour)) continue;
      const key = `${row.dayOfWeek}:${hour}`;
      const existing = counts.get(key);
      if (existing) {
        existing.count += 1;
      } else {
        counts.set(key, {
          dayOfWeek: row.dayOfWeek,
          hour,
          count: 1,
        });
      }
    }
  }

  return [...counts.values()].sort((a, b) => {
    const dayDiff =
      WEEKDAY_UI_ORDER.indexOf(a.dayOfWeek as (typeof WEEKDAY_UI_ORDER)[number]) -
      WEEKDAY_UI_ORDER.indexOf(b.dayOfWeek as (typeof WEEKDAY_UI_ORDER)[number]);
    if (dayDiff !== 0) return dayDiff;
    return a.hour - b.hour;
  });
}

export function pickPeakDayHour(
  cells: RegionDayHourCount[],
): RegionDayHourCount | null {
  const positive = cells.filter((cell) => cell.count > 0);
  if (positive.length === 0) return null;
  return [...positive].sort((a, b) => {
    const countDiff = b.count - a.count;
    if (countDiff !== 0) return countDiff;
    const dayDiff =
      WEEKDAY_UI_ORDER.indexOf(a.dayOfWeek as (typeof WEEKDAY_UI_ORDER)[number]) -
      WEEKDAY_UI_ORDER.indexOf(b.dayOfWeek as (typeof WEEKDAY_UI_ORDER)[number]);
    if (dayDiff !== 0) return dayDiff;
    return a.hour - b.hour;
  })[0]!;
}

export function buildDayHourHeatGrid(
  counts: RegionDayHourCount[],
): DayHourHeatGrid {
  const byKey = new Map(
    counts.map((cell) => [`${cell.dayOfWeek}:${cell.hour}`, cell.count] as const),
  );
  const maxCount = Math.max(0, ...counts.map((cell) => cell.count));
  const peak = pickPeakDayHour(counts);
  const cells: DayHourHeatCell[] = [];

  for (const dayOfWeek of WEEKDAY_UI_ORDER) {
    for (const hour of HAPPY_HOUR_HEAT_HOURS) {
      const count = byKey.get(`${dayOfWeek}:${hour}`) ?? 0;
      const intensity = heatDisplayIntensity(count, maxCount);
      const isPeak = maxCount > 0 && count === maxCount;
      cells.push({
        dayOfWeek,
        hour,
        count,
        intensity,
        color: colorForHeatIntensity(intensity),
        isPeak,
      });
    }
  }

  const total = counts.reduce((sum, cell) => sum + cell.count, 0);

  return {
    hours: HAPPY_HOUR_HEAT_HOURS,
    days: WEEKDAY_UI_ORDER,
    cells,
    peak,
    total,
  };
}

export function dayHourHeatAriaLabel(
  grid: DayHourHeatGrid,
  formatDay: (dayOfWeek: number) => string,
  formatHour: (hour: number) => string,
): string {
  if (!grid.peak || grid.total <= 0) {
    return "No happy hour schedule coverage in the heat map.";
  }
  const peaks = grid.cells.filter((cell) => cell.isPeak);
  const peakShare = Math.round((grid.peak.count / grid.total) * 100);
  if (peaks.length > 1) {
    const labels = peaks
      .map(
        (cell) =>
          `${formatDay(cell.dayOfWeek)} ${formatHour(cell.hour)}`,
      )
      .join(", ");
    return `Happy hour heat map. Tied peaks at ${labels}, each with ${peakShare}% of covered hours.`;
  }
  return `Happy hour heat map. Peak at ${formatDay(grid.peak.dayOfWeek)} ${formatHour(grid.peak.hour)} with ${peakShare}% of covered hours.`;
}

/**
 * Region list href for a heat cell: day + happy hour in the path, and a
 * point-in-time filter at the top of that hour (`startMinute === endMinute`).
 * Example: `/sydney/monday-happyhour?startMinute=1020&endMinute=1020`
 */
export function happyHourHeatCellHref(
  regionListPath: string,
  dayOfWeek: number,
  hour: number,
): string {
  const path = appendFiltersToPath(regionListPath, [dayOfWeek], ["happy hour"]);
  const minute = (((Math.floor(hour) % 24) + 24) % 24) * 60;
  const params = new URLSearchParams({
    startMinute: String(minute),
    endMinute: String(minute),
  });
  return `${path}?${params.toString()}`;
}
