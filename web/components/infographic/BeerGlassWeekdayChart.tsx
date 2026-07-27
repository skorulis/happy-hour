import {
  buildBeerGlassGeometry,
  weekdayMixAriaLabel,
} from "@/lib/infographic/beer-glass";
import { formatDayLabel } from "@/lib/infographic/copy";
import type { RegionWeekdayShare } from "@/lib/infographic/types";

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

  return (
    <div className={className ?? "flex justify-center"}>
      <svg
        viewBox={geometry.chartViewBox}
        className="h-56 w-auto max-w-full sm:h-72"
        role="img"
        aria-label={ariaLabel}
      >
        {geometry.segments.map((segment) => (
          <path
            key={`seg-${segment.dayOfWeek}`}
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
            />
          ) : null,
        )}

        {geometry.legend.map((item) => {
          const isPeak = item.dayOfWeek === peakDayOfWeek;
          return (
            <g key={`legend-${item.dayOfWeek}`}>
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
