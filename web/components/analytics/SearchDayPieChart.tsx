"use client";

import { arc, pie, type PieArcDatum } from "d3";
import type { SearchDayCount } from "@/lib/analytics/queries";
import {
  DAY_ABBREVIATIONS,
  DAY_LABELS,
  WEEKDAY_UI_ORDER,
} from "@/lib/search/schedule";

type SearchDayPieChartProps = {
  data: SearchDayCount[];
};

type ChartDatum = SearchDayCount & {
  label: string;
  shortLabel: string;
  color: string;
};

const ANY_DAY_KEY = "any";
const CHART_COLORS = [
  "var(--chart-1)",
  "var(--chart-2)",
  "var(--chart-3)",
  "var(--chart-4)",
  "var(--chart-5)",
  "var(--chart-6)",
  "var(--chart-7)",
  "var(--chart-8)",
] as const;
const DAY_COLOR: Map<number, string> = new Map(
  WEEKDAY_UI_ORDER.map((day, index) => [day, CHART_COLORS[index + 1]]),
);
const OUTER_RADIUS = 136;
const LABEL_RADIUS = 96;
const countFormatter = new Intl.NumberFormat("en-AU");

export function SearchDayPieChart({ data }: SearchDayPieChartProps) {
  const countByDay = new Map(data.map((datum) => [datum.day, datum.count]));
  const chartData: ChartDatum[] = [];

  const anyDayCount = countByDay.get(null) ?? 0;
  if (anyDayCount > 0) {
    chartData.push({
      day: null,
      count: anyDayCount,
      label: "Any day",
      shortLabel: "Any",
      color: CHART_COLORS[0],
    });
  }

  for (const day of WEEKDAY_UI_ORDER) {
    const dayCount = countByDay.get(day) ?? 0;
    if (dayCount > 0) {
      chartData.push({
        day,
        count: dayCount,
        label: DAY_LABELS[day] ?? `Day ${day}`,
        shortLabel: DAY_ABBREVIATIONS[day] ?? `D${day}`,
        color: DAY_COLOR.get(day) ?? CHART_COLORS[0],
      });
    }
  }

  const total = chartData.reduce((sum, datum) => sum + datum.count, 0);

  if (total === 0) {
    return (
      <p className="py-12 text-center text-sm text-muted">
        No searches recorded yet.
      </p>
    );
  }

  const slices = pie<ChartDatum>()
    .value((datum) => datum.count)
    .sort(null)(chartData);
  const sliceArc = arc<PieArcDatum<ChartDatum>>()
    .innerRadius(0)
    .outerRadius(OUTER_RADIUS);
  const labelArc = arc<PieArcDatum<ChartDatum>>()
    .innerRadius(LABEL_RADIUS)
    .outerRadius(LABEL_RADIUS);

  return (
    <div className="grid items-center gap-8 md:grid-cols-[minmax(0,1fr)_13rem]">
      <div className="mx-auto w-full max-w-lg">
        <svg
          viewBox="-150 -150 300 300"
          role="img"
          aria-labelledby="search-day-chart-title search-day-chart-description"
          className="h-auto w-full overflow-visible"
        >
          <title id="search-day-chart-title">
            Searches by selected day of week
          </title>
          <desc id="search-day-chart-description">
            {chartData
              .map((datum) => `${datum.label}: ${datum.count}`)
              .join(", ")}
          </desc>
          {slices.map((slice, index) => {
            const path = sliceArc(slice);
            const percentage = slice.data.count / total;
            const [labelX, labelY] = labelArc.centroid(slice);

            return (
              <g key={slice.data.day ?? ANY_DAY_KEY}>
                <path
                  d={path ?? undefined}
                  fill={slice.data.color}
                  stroke="var(--background)"
                  strokeWidth={2}
                  className="origin-center animate-dusk-rise motion-reduce:animate-none"
                  style={{ animationDelay: `${index * 60}ms` }}
                />
                {percentage >= 0.06 ? (
                  <text
                    x={labelX}
                    y={labelY}
                    textAnchor="middle"
                    dominantBaseline="central"
                    fill="var(--chart-label)"
                    className="pointer-events-none text-[11px] font-bold"
                  >
                    {Math.round(percentage * 100)}%
                  </text>
                ) : null}
              </g>
            );
          })}
        </svg>
      </div>

      <ul className="space-y-3" aria-label="Search day totals">
        {chartData.map((datum) => (
          <li
            key={datum.day ?? ANY_DAY_KEY}
            className="grid grid-cols-[0.75rem_1fr_auto] items-center gap-3 text-sm"
          >
            <span
              aria-hidden="true"
              className="size-3"
              style={{ backgroundColor: datum.color }}
            />
            <span className="text-secondary">
              <span className="md:hidden">{datum.shortLabel}</span>
              <span className="hidden md:inline">{datum.label}</span>
            </span>
            <span className="font-mono font-medium tabular-nums text-foreground">
              {countFormatter.format(datum.count)}
            </span>
          </li>
        ))}
      </ul>
    </div>
  );
}
