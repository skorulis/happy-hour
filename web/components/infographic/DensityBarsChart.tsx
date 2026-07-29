import {
  buildDensityBarRows,
  formatDensityBarValue,
} from "@/lib/infographic/density-bars";
import type {
  RegionSuburbWinner,
  TopDensityMetric,
} from "@/lib/infographic/types";

type DensityBarsChartProps = {
  suburbs: RegionSuburbWinner[];
  metric: TopDensityMetric;
  className?: string;
  /** Tighter rows for OG / constrained layouts. */
  dense?: boolean;
};

export function DensityBarsChart({
  suburbs,
  metric,
  className,
  dense = false,
}: DensityBarsChartProps) {
  const rows = buildDensityBarRows(suburbs);
  if (rows.length === 0) return null;

  return (
    <div className={className ?? "w-full max-w-2xl"}>
      <ul
        className={`flex flex-col ${dense ? "gap-2" : "gap-3"}`}
        aria-label={
          metric === "density"
            ? "Top suburbs by deals per square kilometre"
            : "Top suburbs by deal count"
        }
      >
        {rows.map((row) => (
          <li
            key={`${row.name}-${row.postcode ?? ""}`}
            className={
              dense
                ? "grid grid-cols-[5.5rem_1fr_3.5rem] items-center gap-2"
                : "grid grid-cols-[8rem_1fr_4.5rem] items-center gap-3"
            }
          >
            <span
              className={`shrink-0 truncate tracking-wide ${
                dense ? "text-xs" : "text-sm"
              } ${
                row.isLeader
                  ? "font-semibold text-foreground"
                  : "font-medium text-secondary"
              }`}
            >
              {row.name}
            </span>
            <div
              className="h-2.5 overflow-hidden rounded-full bg-white/10"
              aria-hidden
            >
              <div
                className="h-full rounded-full"
                style={{
                  width: `${row.widthPercent}%`,
                  backgroundColor: row.color,
                }}
              />
            </div>
            <span
              className={`text-right tabular-nums ${
                dense ? "text-xs" : "text-sm"
              } ${
                row.isLeader ? "font-semibold text-accent-soft" : "text-muted"
              }`}
            >
              {formatDensityBarValue(row.value, metric)}
            </span>
          </li>
        ))}
      </ul>
    </div>
  );
}
