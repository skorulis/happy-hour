import {
  buildBeerGlassGeometry,
  WEEKDAY_CHART_COLORS,
  weekdayMixAriaLabel,
} from "@/lib/infographic/beer-glass";
import { formatDayLabel } from "@/lib/infographic/copy";
import type { RegionWeekdayShare } from "@/lib/infographic/types";
import { DAY_ABBREVIATIONS } from "@/lib/search/schedule";

type BeerGlassWeekdayChartProps = {
  days: RegionWeekdayShare[];
  peakDayOfWeek: number;
  className?: string;
};

export function BeerGlassWeekdayChart({
  days,
  peakDayOfWeek,
  className,
}: BeerGlassWeekdayChartProps) {
  const geometry = buildBeerGlassGeometry(days);
  const ariaLabel = weekdayMixAriaLabel(days, formatDayLabel);
  // Glass stacks Mon→Sun bottom→top; legend reads top→bottom to match the bands.
  const legendDays = [...days].reverse();

  return (
    <div
      className={
        className ??
        "flex flex-col items-center gap-6 sm:flex-row sm:items-stretch sm:justify-center sm:gap-10"
      }
    >
      <svg
        viewBox={geometry.viewBox}
        className="h-56 w-auto shrink-0 sm:h-64"
        role="img"
        aria-label={ariaLabel}
      >
        {geometry.segments.map((segment) => (
          <path
            key={segment.dayOfWeek}
            d={segment.d}
            fill={segment.color}
          />
        ))}
        {geometry.foamPath ? (
          <path d={geometry.foamPath} fill={geometry.foamColor} opacity={0.92} />
        ) : null}
        <path
          d={geometry.outlinePath}
          fill="none"
          stroke={geometry.outlineColor}
          strokeWidth={2.5}
          strokeLinejoin="round"
        />
      </svg>

      <ul className="flex w-auto flex-col justify-between gap-1 py-1 sm:py-2">
        {legendDays.map((day) => {
          const isPeak = day.dayOfWeek === peakDayOfWeek;
          const color =
            WEEKDAY_CHART_COLORS[day.dayOfWeek] ?? geometry.outlineColor;
          return (
            <li
              key={day.dayOfWeek}
              className={`flex items-center gap-2 text-sm ${
                isPeak ? "font-semibold text-foreground" : "text-secondary"
              }`}
            >
              <span
                className="inline-block h-2.5 w-2.5 shrink-0 rounded-sm"
                style={{ backgroundColor: color }}
                aria-hidden
              />
              <span className="min-w-[2.25rem] tracking-wide uppercase">
                {DAY_ABBREVIATIONS[day.dayOfWeek] ?? `D${day.dayOfWeek}`}
              </span>
              <span className={isPeak ? "text-accent-soft" : "text-muted"}>
                {day.percent}%
              </span>
            </li>
          );
        })}
      </ul>
    </div>
  );
}
