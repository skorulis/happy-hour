import { DAY_ABBREVIATIONS, WEEKDAY_UI_ORDER } from "@/lib/search/schedule";
import type {
  RegionDayCount,
  RegionWeekdayShare,
} from "@/lib/infographic/types";

/** Hex colors aligned with `--chart-1`…`--chart-7` (Mon→Sun). */
export const WEEKDAY_CHART_COLORS: Record<number, string> = {
  2: "#f59e0b", // Mon — chart-1
  3: "#38bdf8", // Tue — chart-2
  4: "#a78bfa", // Wed — chart-3
  5: "#34d399", // Thu — chart-4
  6: "#fb7185", // Fri — chart-5
  7: "#fbbf24", // Sat — chart-6
  1: "#22d3ee", // Sun — chart-7
};

export const BEER_GLASS_VIEWBOX = {
  width: 100,
  height: 160,
} as const;

/** Full chart including legend column + leader lines. */
export const BEER_GLASS_CHART_VIEWBOX = {
  width: 210,
  height: 160,
} as const;

const CENTER_X = 50;
const LIQUID_TOP = 30;
const LIQUID_BOTTOM = 138;
const TOP_WIDTH = 56;
const BOTTOM_WIDTH = 34;
const FOAM_TOP = 20;
const FOAM_COLOR = "#f8fafc";
const OUTLINE_COLOR = "#cbd5e1";
const LEADER_COLOR = "#64748b";
const LEGEND_GUTTER_X = 92;
const LEGEND_SWATCH_X = 118;
const LEGEND_SWATCH_SIZE = 6;
const LEGEND_LABEL_X = 128;
const LEGEND_TOP = 26;
const LEGEND_BOTTOM = 142;

export type BeerGlassSegment = {
  dayOfWeek: number;
  d: string;
  color: string;
  percent: number;
  count: number;
  yTop: number;
  yBottom: number;
  yMid: number;
  xRight: number;
};

export type BeerGlassLegendItem = {
  dayOfWeek: number;
  label: string;
  percent: number;
  count: number;
  color: string;
  y: number;
  swatchX: number;
  swatchSize: number;
  labelX: number;
  /** Elbow path from segment edge to legend swatch; null when percent is 0. */
  leaderPath: string | null;
};

export type BeerGlassGeometry = {
  viewBox: string;
  chartViewBox: string;
  outlinePath: string;
  foamPath: string | null;
  segments: BeerGlassSegment[];
  legend: BeerGlassLegendItem[];
  outlineColor: string;
  foamColor: string;
  leaderColor: string;
};

/**
 * Largest-remainder percentages that sum to 100.
 * Days with count 0 still get an entry with percent 0 (omitted from geometry fill).
 */
export function normalizeWeekdayPercents(
  dayCounts: RegionDayCount[],
): RegionWeekdayShare[] {
  const countByDay = new Map(
    dayCounts.map((row) => [row.dayOfWeek, row.count]),
  );
  const ordered = WEEKDAY_UI_ORDER.map((dayOfWeek) => ({
    dayOfWeek,
    count: countByDay.get(dayOfWeek) ?? 0,
  }));
  const total = ordered.reduce((sum, row) => sum + row.count, 0);
  if (total <= 0) {
    return ordered.map((row) => ({ ...row, percent: 0 }));
  }

  const raw = ordered.map((row) => ({
    ...row,
    exact: (row.count / total) * 100,
  }));
  const floored = raw.map((row) => ({
    ...row,
    percent: Math.floor(row.exact),
    fraction: row.exact - Math.floor(row.exact),
  }));
  let remainder = 100 - floored.reduce((sum, row) => sum + row.percent, 0);
  const byFraction = [...floored].sort((a, b) => {
    const fractionDiff = b.fraction - a.fraction;
    if (fractionDiff !== 0) return fractionDiff;
    return a.dayOfWeek - b.dayOfWeek;
  });
  for (const row of byFraction) {
    if (remainder <= 0) break;
    if (row.count <= 0) continue;
    row.percent += 1;
    remainder -= 1;
  }

  if (remainder > 0) {
    const peak = byFraction.find((row) => row.count > 0) ?? byFraction[0];
    if (peak) {
      peak.percent += remainder;
    }
  }

  const percentByDay = new Map(
    floored.map((row) => [row.dayOfWeek, row.percent]),
  );
  return ordered.map((row) => ({
    dayOfWeek: row.dayOfWeek,
    count: row.count,
    percent: percentByDay.get(row.dayOfWeek) ?? 0,
  }));
}

function widthAtY(y: number): number {
  const t = (LIQUID_BOTTOM - y) / (LIQUID_BOTTOM - LIQUID_TOP);
  const clamped = Math.min(1, Math.max(0, t));
  return BOTTOM_WIDTH + clamped * (TOP_WIDTH - BOTTOM_WIDTH);
}

function edgesAtY(y: number): { left: number; right: number } {
  const width = widthAtY(y);
  return {
    left: CENTER_X - width / 2,
    right: CENTER_X + width / 2,
  };
}

function bandPath(yBottom: number, yTop: number): string {
  const bottom = edgesAtY(yBottom);
  const top = edgesAtY(yTop);
  return [
    `M ${bottom.left.toFixed(2)} ${yBottom.toFixed(2)}`,
    `L ${bottom.right.toFixed(2)} ${yBottom.toFixed(2)}`,
    `L ${top.right.toFixed(2)} ${yTop.toFixed(2)}`,
    `L ${top.left.toFixed(2)} ${yTop.toFixed(2)}`,
    "Z",
  ].join(" ");
}

function buildOutlinePath(): string {
  const rim = edgesAtY(FOAM_TOP);
  const liquidTop = edgesAtY(LIQUID_TOP);
  const base = edgesAtY(LIQUID_BOTTOM);
  const footY = 148;
  const footLeft = CENTER_X - 22;
  const footRight = CENTER_X + 22;
  return [
    `M ${rim.left.toFixed(2)} ${FOAM_TOP.toFixed(2)}`,
    `L ${rim.right.toFixed(2)} ${FOAM_TOP.toFixed(2)}`,
    `L ${liquidTop.right.toFixed(2)} ${LIQUID_TOP.toFixed(2)}`,
    `L ${base.right.toFixed(2)} ${LIQUID_BOTTOM.toFixed(2)}`,
    `L ${footRight.toFixed(2)} ${footY.toFixed(2)}`,
    `L ${footLeft.toFixed(2)} ${footY.toFixed(2)}`,
    `L ${base.left.toFixed(2)} ${LIQUID_BOTTOM.toFixed(2)}`,
    `L ${liquidTop.left.toFixed(2)} ${LIQUID_TOP.toFixed(2)}`,
    "Z",
  ].join(" ");
}

function buildFoamPath(): string {
  return bandPath(LIQUID_TOP, FOAM_TOP);
}

function leaderElbow(
  fromX: number,
  fromY: number,
  toX: number,
  toY: number,
): string {
  const gutterX = LEGEND_GUTTER_X;
  return [
    `M ${fromX.toFixed(2)} ${fromY.toFixed(2)}`,
    `L ${gutterX.toFixed(2)} ${fromY.toFixed(2)}`,
    `L ${gutterX.toFixed(2)} ${toY.toFixed(2)}`,
    `L ${toX.toFixed(2)} ${toY.toFixed(2)}`,
  ].join(" ");
}

/**
 * Build tapered stacked bands for Mon→Sun (bottom→top), plus legend
 * positions (Sun→Mon top→bottom) and elbow leader lines.
 */
export function buildBeerGlassGeometry(
  days: RegionWeekdayShare[],
): BeerGlassGeometry {
  const liquidHeight = LIQUID_BOTTOM - LIQUID_TOP;
  const fillDays = days.filter((day) => day.percent > 0);
  const segments: BeerGlassSegment[] = [];
  let yBottom = LIQUID_BOTTOM;

  for (const day of fillDays) {
    const height = (day.percent / 100) * liquidHeight;
    const yTop = yBottom - height;
    const yMid = (yTop + yBottom) / 2;
    const xRight = edgesAtY(yMid).right;
    segments.push({
      dayOfWeek: day.dayOfWeek,
      d: bandPath(yBottom, yTop),
      color: WEEKDAY_CHART_COLORS[day.dayOfWeek] ?? "#f59e0b",
      percent: day.percent,
      count: day.count,
      yTop,
      yBottom,
      yMid,
      xRight,
    });
    yBottom = yTop;
  }

  const segmentByDay = new Map(
    segments.map((segment) => [segment.dayOfWeek, segment]),
  );

  // Legend top→bottom matches glass top→bottom (Sun→Mon).
  const legendDays = [...days].reverse();
  const legendCount = Math.max(legendDays.length, 1);
  const legendSpan = LEGEND_BOTTOM - LEGEND_TOP;
  const legend = legendDays.map((day, index) => {
    const t = legendCount === 1 ? 0 : index / (legendCount - 1);
    const y = LEGEND_TOP + t * legendSpan;
    const segment = segmentByDay.get(day.dayOfWeek);
    const color = WEEKDAY_CHART_COLORS[day.dayOfWeek] ?? "#f59e0b";
    const swatchCenterX = LEGEND_SWATCH_X + LEGEND_SWATCH_SIZE / 2;
    return {
      dayOfWeek: day.dayOfWeek,
      label: DAY_ABBREVIATIONS[day.dayOfWeek] ?? `D${day.dayOfWeek}`,
      percent: day.percent,
      count: day.count,
      color,
      y,
      swatchX: LEGEND_SWATCH_X,
      swatchSize: LEGEND_SWATCH_SIZE,
      labelX: LEGEND_LABEL_X,
      leaderPath: segment
        ? leaderElbow(segment.xRight, segment.yMid, swatchCenterX, y)
        : null,
    };
  });

  return {
    viewBox: `0 0 ${BEER_GLASS_VIEWBOX.width} ${BEER_GLASS_VIEWBOX.height}`,
    chartViewBox: `0 0 ${BEER_GLASS_CHART_VIEWBOX.width} ${BEER_GLASS_CHART_VIEWBOX.height}`,
    outlinePath: buildOutlinePath(),
    foamPath: fillDays.length > 0 ? buildFoamPath() : null,
    segments,
    legend,
    outlineColor: OUTLINE_COLOR,
    foamColor: FOAM_COLOR,
    leaderColor: LEADER_COLOR,
  };
}

export function weekdayMixAriaLabel(
  days: RegionWeekdayShare[],
  dayLabel: (dayOfWeek: number) => string,
): string {
  const parts = days
    .filter((day) => day.percent > 0)
    .map((day) => `${dayLabel(day.dayOfWeek)} ${day.percent}%`);
  return parts.length > 0
    ? `Deal schedule mix by day: ${parts.join(", ")}`
    : "No scheduled deals by day";
}
