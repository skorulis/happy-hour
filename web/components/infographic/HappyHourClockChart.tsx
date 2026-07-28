import {
  buildHappyHourClockGeometry,
  formatHourLabel,
  startHourMixAriaLabel,
} from "@/lib/infographic/happy-hour-clock";
import type { RegionStartHourShare } from "@/lib/infographic/types";

type HappyHourClockChartProps = {
  hours: RegionStartHourShare[];
  peakHour: number;
  className?: string;
};

export function HappyHourClockChart({
  hours,
  peakHour,
  className,
}: HappyHourClockChartProps) {
  const geometry = buildHappyHourClockGeometry(hours, peakHour);
  const ariaLabel = startHourMixAriaLabel(hours, peakHour);
  const peakPercent =
    hours.find((row) => row.hour === peakHour)?.percent ?? null;

  return (
    <div className={className ?? "flex justify-start"}>
      <svg
        viewBox={geometry.viewBox}
        className="h-56 w-auto max-w-full sm:h-72"
        role="img"
        aria-label={ariaLabel}
      >
        <circle
          cx={geometry.centerX}
          cy={geometry.centerY}
          r={geometry.faceR}
          fill={geometry.faceColor}
          stroke={geometry.outlineColor}
          strokeWidth={2}
        />

        {geometry.wedges.map((wedge) => (
          <path
            key={`wedge-${wedge.hour}`}
            d={wedge.pathD}
            fill={wedge.color}
          />
        ))}

        <circle
          cx={geometry.centerX}
          cy={geometry.centerY}
          r={geometry.innerR}
          fill={geometry.faceColor}
          stroke={geometry.outlineColor}
          strokeWidth={1.5}
        />

        {geometry.ticks.map((tick) => (
          <g key={`tick-${tick.hour}`}>
            <line
              x1={tick.x1}
              y1={tick.y1}
              x2={tick.x2}
              y2={tick.y2}
              stroke={geometry.outlineColor}
              strokeWidth={1.5}
              strokeLinecap="round"
            />
            <text
              x={tick.x}
              y={tick.y}
              textAnchor="middle"
              dominantBaseline="central"
              fill="#94a3b8"
              fontSize={11}
              fontWeight={600}
            >
              {tick.label}
            </text>
          </g>
        ))}

        <text
          x={geometry.centerX}
          y={geometry.centerY - 6}
          textAnchor="middle"
          dominantBaseline="central"
          fill="#f8fafc"
          fontSize={18}
          fontWeight={700}
        >
          {formatHourLabel(peakHour)}
        </text>
        {peakPercent !== null ? (
          <text
            x={geometry.centerX}
            y={geometry.centerY + 12}
            textAnchor="middle"
            dominantBaseline="central"
            fill="#fdba74"
            fontSize={11}
            fontWeight={600}
          >
            {`${peakPercent}%`}
          </text>
        ) : null}
      </svg>
    </div>
  );
}
