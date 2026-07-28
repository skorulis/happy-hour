import {
  buildDayHourHeatGrid,
  dayHourHeatAriaLabel,
} from "@/lib/infographic/day-hour-heat";
import {
  formatDayAbbrev,
  formatDayLabel,
  formatHourLabel,
} from "@/lib/infographic/copy";
import type { RegionDayHourCount } from "@/lib/infographic/types";

type DayHourHeatChartProps = {
  cells: RegionDayHourCount[];
  className?: string;
};

export function DayHourHeatChart({ cells, className }: DayHourHeatChartProps) {
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
                return (
                  <div
                    key={`c-${dayOfWeek}-${hour}`}
                    title={`${formatDayAbbrev(dayOfWeek)} ${formatHourLabel(hour)}: ${cell.count}`}
                    className={[
                      "aspect-square min-h-4 rounded-[3px]",
                      cell.isPeak
                        ? "ring-2 ring-accent-soft ring-offset-1 ring-offset-[#081426]"
                        : "",
                    ].join(" ")}
                    style={{ backgroundColor: cell.color }}
                  />
                );
              })}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
