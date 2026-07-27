import { DAY_ABBREVIATIONS, WEEKDAY_UI_ORDER } from "@/lib/search/schedule";
import type {
  RegionDayCount,
  RegionWeekdayShare,
} from "@/lib/infographic/types";

/**
 * Beer SRM ramp for the schooner stack (Mon bottom → Sat near foam).
 * Named steps match common SRM charts (Deep Amber → Pale Straw);
 * Sunday stays foam white as the head.
 * @see https://beermaverick.com/understanding-srm-and-lovibond-beer-color-calculations/
 */
export const WEEKDAY_CHART_COLORS: Record<number, string> = {
  2: "#a63e00", // Mon — Amber Brown ~SRM 18
  3: "#bb5100", // Tue — Deep Amber ~SRM 15
  4: "#cf6900", // Wed — Medium Amber ~SRM 12
  5: "#e58500", // Thu — Pale Amber ~SRM 9
  6: "#f8a600", // Fri — Deep Gold ~SRM 6
  7: "#ffd878", // Sat — Pale Straw ~SRM 2
  1: "#f8fafc", // Sun — foam white (top band)
};

const FALLBACK_BAND_COLOR = WEEKDAY_CHART_COLORS[5]!;

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
/** Top of stacked day bands (rim); Sunday occupies this as the white “head”. */
const LIQUID_TOP = 18;
const LIQUID_BOTTOM = 140;
const FOOT_Y = 152;
const OUTLINE_COLOR = "#cbd5e1";
const LEADER_COLOR = "#64748b";
const LEGEND_GUTTER_X = 94;
const LEGEND_SWATCH_X = 120;
const LEGEND_SWATCH_SIZE = 6;
const LEGEND_LABEL_X = 130;
const LEGEND_TOP = 24;
const LEGEND_BOTTOM = 148;

/**
 * Schooner half-width keyframes (rim → bowl → taper → foot).
 * Walls are cubic Beziers through these points; left mirrors right.
 */
const PROFILE: Array<{ y: number; halfWidth: number }> = [
  { y: LIQUID_TOP, halfWidth: 30 },
  { y: 36, halfWidth: 34 },
  { y: 58, halfWidth: 33 },
  { y: 88, halfWidth: 26 },
  { y: 118, halfWidth: 18 },
  { y: LIQUID_BOTTOM, halfWidth: 14 },
  { y: 146, halfWidth: 16 },
  { y: FOOT_Y, halfWidth: 22 },
];

type Point = { x: number; y: number };

export type BeerGlassSegment = {
  dayOfWeek: number;
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
  /** Smooth filled schooner path used as clip for day bands. */
  clipPath: string;
  /** Smooth stroked outline (includes foot). */
  outlinePath: string;
  segments: BeerGlassSegment[];
  legend: BeerGlassLegendItem[];
  outlineColor: string;
  leaderColor: string;
  glassWidth: number;
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

function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

function smoothstep(t: number): number {
  const x = Math.min(1, Math.max(0, t));
  return x * x * (3 - 2 * x);
}

/** Half-width of the schooner silhouette at a given y (for leader anchors). */
function halfWidthAtY(y: number): number {
  if (y <= PROFILE[0]!.y) return PROFILE[0]!.halfWidth;
  const last = PROFILE[PROFILE.length - 1]!;
  if (y >= last.y) return last.halfWidth;

  for (let i = 0; i < PROFILE.length - 1; i += 1) {
    const a = PROFILE[i]!;
    const b = PROFILE[i + 1]!;
    if (y >= a.y && y <= b.y) {
      const t = smoothstep((y - a.y) / (b.y - a.y));
      return lerp(a.halfWidth, b.halfWidth, t);
    }
  }
  return last.halfWidth;
}

function rightEdgePoints(yMax: number): Point[] {
  return PROFILE.filter((p) => p.y <= yMax + 0.001).map((p) => ({
    x: CENTER_X + p.halfWidth,
    y: p.y,
  }));
}

function fmt(point: Point): string {
  return `${point.x.toFixed(2)} ${point.y.toFixed(2)}`;
}

function mirrorX(point: Point): Point {
  return { x: 2 * CENTER_X - point.x, y: point.y };
}

type Cubic = { c1: Point; c2: Point; end: Point };

/** Open Catmull-Rom cubics through points (top → bottom on the right wall). */
function cubicsThrough(points: Point[]): Cubic[] {
  if (points.length < 2) return [];
  const cubics: Cubic[] = [];
  for (let i = 0; i < points.length - 1; i += 1) {
    const p0 = points[i === 0 ? i : i - 1]!;
    const p1 = points[i]!;
    const p2 = points[i + 1]!;
    const p3 = points[i + 2 < points.length ? i + 2 : i + 1]!;
    cubics.push({
      c1: {
        x: p1.x + (p2.x - p0.x) / 6,
        y: p1.y + (p2.y - p0.y) / 6,
      },
      c2: {
        x: p2.x - (p3.x - p1.x) / 6,
        y: p2.y - (p3.y - p1.y) / 6,
      },
      end: p2,
    });
  }
  return cubics;
}

function cubicCommand(cubic: Cubic): string {
  return `C ${fmt(cubic.c1)} ${fmt(cubic.c2)} ${fmt(cubic.end)}`;
}

/**
 * Smooth symmetric schooner: rim → down right wall → across base → up left wall.
 * Explicit base join avoids the left-wall curve starting from the wrong point
 * (which previously sliced across the lower bands).
 */
function buildSilhouettePath(yMax: number): string {
  const rightDown = rightEdgePoints(yMax);
  if (rightDown.length < 2) return "";

  const rightCubics = cubicsThrough(rightDown);
  const bottomRight = rightDown[rightDown.length - 1]!;
  const bottomLeft = mirrorX(bottomRight);
  const rimRight = rightDown[0]!;
  const rimLeft = mirrorX(rimRight);

  // Mirror + reverse each right-wall cubic for the ascent up the left wall.
  const leftUpCommands: string[] = [];
  for (let i = rightCubics.length - 1; i >= 0; i -= 1) {
    const cubic = rightCubics[i]!;
    const startPt = rightDown[i]!;
    leftUpCommands.push(
      cubicCommand({
        c1: mirrorX(cubic.c2),
        c2: mirrorX(cubic.c1),
        end: mirrorX(startPt),
      }),
    );
  }

  return [
    `M ${fmt(rimLeft)}`,
    `L ${fmt(rimRight)}`,
    ...rightCubics.map(cubicCommand),
    `L ${fmt(bottomLeft)}`,
    ...leftUpCommands,
    "Z",
  ].join(" ");
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
 * Build stacked weekday bands (clipped to a smooth schooner), plus legend
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
    segments.push({
      dayOfWeek: day.dayOfWeek,
      color: WEEKDAY_CHART_COLORS[day.dayOfWeek] ?? FALLBACK_BAND_COLOR,
      percent: day.percent,
      count: day.count,
      yTop,
      yBottom,
      yMid,
      xRight: CENTER_X + halfWidthAtY(yMid),
    });
    yBottom = yTop;
  }

  const segmentByDay = new Map(
    segments.map((segment) => [segment.dayOfWeek, segment]),
  );

  const legendDays = [...days].reverse();
  const legendCount = Math.max(legendDays.length, 1);
  const legendSpan = LEGEND_BOTTOM - LEGEND_TOP;
  const legend = legendDays.map((day, index) => {
    const t = legendCount === 1 ? 0 : index / (legendCount - 1);
    const y = LEGEND_TOP + t * legendSpan;
    const segment = segmentByDay.get(day.dayOfWeek);
    const color = WEEKDAY_CHART_COLORS[day.dayOfWeek] ?? FALLBACK_BAND_COLOR;
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

  const clipPath = buildSilhouettePath(LIQUID_BOTTOM);
  const outlinePath = buildSilhouettePath(FOOT_Y);

  return {
    viewBox: `0 0 ${BEER_GLASS_VIEWBOX.width} ${BEER_GLASS_VIEWBOX.height}`,
    chartViewBox: `0 0 ${BEER_GLASS_CHART_VIEWBOX.width} ${BEER_GLASS_CHART_VIEWBOX.height}`,
    clipPath,
    outlinePath,
    segments,
    legend,
    outlineColor: OUTLINE_COLOR,
    leaderColor: LEADER_COLOR,
    glassWidth: BEER_GLASS_VIEWBOX.width,
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
