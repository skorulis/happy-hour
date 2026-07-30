import { useId } from "react";
import {
  buildBeerGlassGeometry,
  weekdayMixAriaLabel,
  weekdayMixDayHref,
} from "@/lib/infographic/beer-glass";
import { formatDayLabel } from "@/lib/infographic/copy";
import type { RegionWeekdayShare } from "@/lib/infographic/types";

type BeerGlassWeekdayChartProps = {
  days: RegionWeekdayShare[];
  peakDayOfWeek: number;
  /** Deal list base path (`/sydney` or `/surry-hills-2010`). */
  listBasePath: string;
  className?: string;
};

export function BeerGlassWeekdayChart({
  days,
  peakDayOfWeek,
  listBasePath,
  className,
}: BeerGlassWeekdayChartProps) {
  const clipId = useId().replace(/:/g, "");
  const geometry = buildBeerGlassGeometry(days);
  const ariaLabel = weekdayMixAriaLabel(days, formatDayLabel);

  return (
    <div className={className ?? "flex justify-start"}>
      <svg
        viewBox={geometry.chartViewBox}
        className="h-56 w-auto max-w-full @sm:h-72"
        role="group"
        aria-label={ariaLabel}
      >
        <defs>
          <clipPath id={clipId}>
            <path d={geometry.clipPath} />
          </clipPath>
        </defs>

        <g clipPath={`url(#${clipId})`}>
          {geometry.segments.map((segment) => {
            const href = weekdayMixDayHref(listBasePath, segment.dayOfWeek);
            const label = `${formatDayLabel(segment.dayOfWeek)} deals — open search`;
            return (
              <a
                key={`seg-${segment.dayOfWeek}`}
                href={href}
                aria-label={label}
                className="outline-offset-2 transition-[filter] hover:brightness-125 focus-visible:outline focus-visible:outline-2 focus-visible:outline-accent-soft"
              >
                <title>{label}</title>
                <rect
                  x={0}
                  y={segment.yTop}
                  width={geometry.glassWidth}
                  height={segment.yBottom - segment.yTop}
                  fill={segment.color}
                />
              </a>
            );
          })}
        </g>

        <path
          d={geometry.outlinePath}
          fill="none"
          stroke={geometry.outlineColor}
          strokeWidth={2.25}
          strokeLinejoin="round"
          pointerEvents="none"
        />

        {geometry.legend.map((item) =>
          item.leaderPath ? (
            <path
              key={`leader-${item.dayOfWeek}`}
              d={item.leaderPath}
              fill="none"
              stroke={geometry.leaderColor}
              strokeWidth={1.25}
              strokeLinecap="round"
              strokeLinejoin="round"
              opacity={0.85}
              pointerEvents="none"
            />
          ) : null,
        )}

        {geometry.legend.map((item) => {
          const isPeak = item.dayOfWeek === peakDayOfWeek;
          return (
            <g key={`legend-${item.dayOfWeek}`} pointerEvents="none">
              <rect
                x={item.swatchX}
                y={item.y - item.swatchSize / 2}
                width={item.swatchSize}
                height={item.swatchSize}
                rx={1}
                fill={item.color}
              />
              <text
                x={item.labelX}
                y={item.y}
                dominantBaseline="middle"
                fill={isPeak ? "#f8fafc" : "#cbd5e1"}
                style={{
                  fontSize: 9,
                  fontWeight: isPeak ? 700 : 500,
                  letterSpacing: "0.06em",
                }}
              >
                {item.label}
              </text>
              <text
                x={item.labelX + 28}
                y={item.y}
                dominantBaseline="middle"
                fill={isPeak ? "#fdba74" : "#94a3b8"}
                style={{
                  fontSize: 9,
                  fontWeight: isPeak ? 700 : 500,
                }}
              >
                {item.percent}%
              </text>
            </g>
          );
        })}
      </svg>
    </div>
  );
}
