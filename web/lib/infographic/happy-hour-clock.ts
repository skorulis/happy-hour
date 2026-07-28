import type { RegionStartHourCount, RegionStartHourShare } from "@/lib/infographic/types";

/**
 * Happy-hour clock face: noon → 11pm (12 positions, 12 at top).
 * Morning starts are omitted from the dial; peak is still picked from this window.
 */
export const HAPPY_HOUR_CLOCK_HOURS = [
  12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
] as const;

/** Amber intensity ramp: quiet → peak (matches drink-bar SRM feel). */
export const CLOCK_HOUR_COLORS = [
  "#3b414d", // empty / near-zero
  "#7c3a28",
  "#a63e00",
  "#bb5100",
  "#cf6900",
  "#e58500",
  "#f8a600",
  "#ffd878",
] as const;

export const CLOCK_VIEWBOX = {
  width: 240,
  height: 240,
} as const;

const CENTER = { x: 120, y: 120 };
const INNER_R = 36;
const OUTER_R = 88;
const TICK_R = 94;
const LABEL_R = 108;
const WEDGE_GAP_DEG = 3;
const OUTLINE_COLOR = "#2b3541";
const FACE_COLOR = "#0c1524";

export type ClockWedge = {
  hour: number;
  count: number;
  percent: number;
  color: string;
  pathD: string;
  /** Mid-angle in degrees clockwise from 12 o'clock. */
  midAngleDeg: number;
};

export type ClockTick = {
  hour: number;
  label: string;
  x: number;
  y: number;
  /** Short radial tick from rim. */
  x1: number;
  y1: number;
  x2: number;
  y2: number;
};

export type HappyHourClockGeometry = {
  viewBox: string;
  wedges: ClockWedge[];
  ticks: ClockTick[];
  peakHour: number | null;
  outlineColor: string;
  faceColor: string;
  centerX: number;
  centerY: number;
  innerR: number;
  faceR: number;
};

function clampHour(hour: number): number {
  return ((Math.floor(hour) % 24) + 24) % 24;
}

/** 12 at top → 0°, then clockwise 30° per hour. */
export function hourToClockAngleDeg(hour: number): number {
  return (clampHour(hour) % 12) * 30;
}

export function formatHourLabel(hour: number): string {
  const h = clampHour(hour);
  const suffix = h >= 12 ? "pm" : "am";
  const h12 = h % 12 || 12;
  return `${h12}${suffix}`;
}

function polar(cx: number, cy: number, r: number, angleDeg: number): {
  x: number;
  y: number;
} {
  const rad = ((angleDeg - 90) * Math.PI) / 180;
  return {
    x: cx + r * Math.cos(rad),
    y: cy + r * Math.sin(rad),
  };
}

function annularWedgePath(
  cx: number,
  cy: number,
  innerR: number,
  outerR: number,
  startDeg: number,
  endDeg: number,
): string {
  const largeArc = endDeg - startDeg > 180 ? 1 : 0;
  const o1 = polar(cx, cy, outerR, startDeg);
  const o2 = polar(cx, cy, outerR, endDeg);
  const i2 = polar(cx, cy, innerR, endDeg);
  const i1 = polar(cx, cy, innerR, startDeg);
  return [
    `M ${o1.x.toFixed(2)} ${o1.y.toFixed(2)}`,
    `A ${outerR} ${outerR} 0 ${largeArc} 1 ${o2.x.toFixed(2)} ${o2.y.toFixed(2)}`,
    `L ${i2.x.toFixed(2)} ${i2.y.toFixed(2)}`,
    `A ${innerR} ${innerR} 0 ${largeArc} 0 ${i1.x.toFixed(2)} ${i1.y.toFixed(2)}`,
    "Z",
  ].join(" ");
}

function colorForShare(count: number, maxCount: number): string {
  if (count <= 0 || maxCount <= 0) {
    return CLOCK_HOUR_COLORS[0]!;
  }
  const t = count / maxCount;
  const index = Math.min(
    CLOCK_HOUR_COLORS.length - 1,
    Math.max(1, Math.round(t * (CLOCK_HOUR_COLORS.length - 1))),
  );
  return CLOCK_HOUR_COLORS[index]!;
}

/**
 * Largest-remainder percents over the noon→11pm window (sums to 100 when
 * total count > 0). Hours outside the window are ignored.
 */
export function normalizeStartHourShares(
  hourCounts: RegionStartHourCount[],
): RegionStartHourShare[] {
  const byHour = new Map(
    hourCounts.map((row) => [clampHour(row.hour), row.count] as const),
  );
  const rows = HAPPY_HOUR_CLOCK_HOURS.map((hour) => ({
    hour,
    count: byHour.get(hour) ?? 0,
  }));
  const total = rows.reduce((sum, row) => sum + row.count, 0);
  if (total <= 0) {
    return rows.map((row) => ({ ...row, percent: 0 }));
  }

  const floored = rows.map((row) => {
    const exact = (row.count / total) * 100;
    return {
      ...row,
      exact,
      percent: Math.floor(exact),
      fraction: exact - Math.floor(exact),
    };
  });
  let remainder = 100 - floored.reduce((sum, row) => sum + row.percent, 0);
  const byFraction = [...floored].sort((a, b) => {
    const fractionDiff = b.fraction - a.fraction;
    if (fractionDiff !== 0) return fractionDiff;
    return a.hour - b.hour;
  });
  for (const row of byFraction) {
    if (remainder <= 0) break;
    if (row.count <= 0) continue;
    row.percent += 1;
    remainder -= 1;
  }
  if (remainder > 0) {
    const peak = byFraction.find((row) => row.count > 0) ?? byFraction[0];
    if (peak) peak.percent += remainder;
  }

  return floored.map(({ hour, count, percent }) => ({ hour, count, percent }));
}

export function pickPeakStartHour(
  hourCounts: RegionStartHourCount[],
): RegionStartHourCount | null {
  const inWindow = (hourCounts ?? [])
    .map((row) => ({ hour: clampHour(row.hour), count: row.count }))
    .filter(
      (row) =>
        row.count > 0 &&
        (HAPPY_HOUR_CLOCK_HOURS as readonly number[]).includes(row.hour),
    );
  if (inWindow.length === 0) return null;
  return [...inWindow].sort((a, b) => {
    const countDiff = b.count - a.count;
    if (countDiff !== 0) return countDiff;
    return a.hour - b.hour;
  })[0]!;
}

export function buildHappyHourClockGeometry(
  hours: RegionStartHourShare[],
  peakHour: number | null,
): HappyHourClockGeometry {
  const maxCount = Math.max(0, ...hours.map((row) => row.count));
  const wedges: ClockWedge[] = [];

  for (const row of hours) {
    if (row.count <= 0) continue;
    const mid = hourToClockAngleDeg(row.hour);
    const halfSpan = (30 - WEDGE_GAP_DEG) / 2;
    const startDeg = mid - halfSpan;
    const endDeg = mid + halfSpan;
    const t = maxCount > 0 ? row.count / maxCount : 0;
    const outerR = INNER_R + (OUTER_R - INNER_R) * Math.max(0.18, t);
    wedges.push({
      hour: row.hour,
      count: row.count,
      percent: row.percent,
      color: colorForShare(row.count, maxCount),
      pathD: annularWedgePath(
        CENTER.x,
        CENTER.y,
        INNER_R,
        outerR,
        startDeg,
        endDeg,
      ),
      midAngleDeg: mid,
    });
  }

  const ticks: ClockTick[] = HAPPY_HOUR_CLOCK_HOURS.filter(
    (hour) => hour % 3 === 0,
  ).map((hour) => {
    const angle = hourToClockAngleDeg(hour);
    const labelPos = polar(CENTER.x, CENTER.y, LABEL_R, angle);
    const tickInner = polar(CENTER.x, CENTER.y, TICK_R - 4, angle);
    const tickOuter = polar(CENTER.x, CENTER.y, TICK_R + 2, angle);
    return {
      hour,
      label: formatHourLabel(hour),
      x: labelPos.x,
      y: labelPos.y,
      x1: tickInner.x,
      y1: tickInner.y,
      x2: tickOuter.x,
      y2: tickOuter.y,
    };
  });

  return {
    viewBox: `0 0 ${CLOCK_VIEWBOX.width} ${CLOCK_VIEWBOX.height}`,
    wedges,
    ticks,
    peakHour,
    outlineColor: OUTLINE_COLOR,
    faceColor: FACE_COLOR,
    centerX: CENTER.x,
    centerY: CENTER.y,
    innerR: INNER_R,
    faceR: OUTER_R + 6,
  };
}

export function startHourMixAriaLabel(
  hours: RegionStartHourShare[],
  peakHour: number | null,
): string {
  const peak =
    peakHour !== null
      ? `Peak start time ${formatHourLabel(peakHour)}. `
      : "";
  const parts = hours
    .filter((row) => row.count > 0)
    .map((row) => `${formatHourLabel(row.hour)} ${row.percent}%`);
  return `${peak}Deal start times: ${parts.join(", ") || "none"}.`;
}
