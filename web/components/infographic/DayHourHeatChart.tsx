import Link from "next/link";
import { Flame } from "lucide-react";
import {
  buildDayHourHeatGrid,
  dayHourHeatAriaLabel,
  happyHourHeatCellHref,
} from "@/lib/infographic/day-hour-heat";
import {
  formatDayAbbrev,
  formatDayLabel,
  formatHourLabel,
} from "@/lib/infographic/copy";
import type { RegionDayHourCount } from "@/lib/infographic/types";

type DayHourHeatChartProps = {
  cells: RegionDayHourCount[];
  /** Deal list base path (`/sydney` or `/surry-hills-2010`). */
  listBasePath: string;
  className?: string;
};

export function DayHourHeatChart({
  cells,
  listBasePath,
  className,
}: DayHourHeatChartProps) {
  const grid = buildDayHourHeatGrid(cells);
  const ariaLabel = dayHourHeatAriaLabel(
    grid,
    formatDayLabel,
    formatHourLabel,
  );
  const hourLabels = new Set(grid.hours.filter((hour) => hour % 2 === 0));
  const cellByKey = new Map(
    grid.cells.map((cell) => [`${cell.dayOfWeek}:${cell.hour}`, cell] as const),
  );

  return (
    <div className={className ?? "w-full max-w-xl"}>
      <div className="overflow-x-auto" role="img" aria-label={ariaLabel}>
        <div
          className="inline-grid gap-1"
          style={{
            gridTemplateColumns: `2.5rem repeat(${grid.hours.length}, minmax(1.1rem, 1fr))`,
          }}
        >
          <div aria-hidden />
          {grid.hours.map((hour) => (
            <div
              key={`h-${hour}`}
              className="flex h-5 items-end justify-center text-[10px] font-medium text-muted"
            >
              {hourLabels.has(hour) ? formatHourLabel(hour) : ""}
            </div>
          ))}

          {grid.days.map((dayOfWeek) => (
            <div key={`row-${dayOfWeek}`} className="contents">
              <div className="flex items-center text-xs font-semibold tracking-wide text-secondary">
                {formatDayAbbrev(dayOfWeek)}
              </div>
              {grid.hours.map((hour) => {
                const cell = cellByKey.get(`${dayOfWeek}:${hour}`)!;
                const href = happyHourHeatCellHref(
                  listBasePath,
                  dayOfWeek,
                  hour,
                );
                const label = `${formatDayAbbrev(dayOfWeek)} ${formatHourLabel(hour)}: ${cell.count} — open search`;
                return (
                  <Link
                    key={`c-${dayOfWeek}-${hour}`}
                    href={href}
                    title={label}
                    aria-label={label}
                    className="relative flex aspect-square min-h-4 items-center justify-center rounded-[3px] outline-offset-2 transition-[filter] hover:brightness-125 focus-visible:outline focus-visible:outline-2 focus-visible:outline-accent-soft"
                    style={{ backgroundColor: cell.color }}
                  >
                    {cell.isPeak ? (
                      <Flame
                        aria-hidden
                        className="h-[72%] w-[72%] text-[#081426]"
                        strokeWidth={2.5}
                      />
                    ) : null}
                  </Link>
                );
              })}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
