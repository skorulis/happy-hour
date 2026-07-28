import { buildDrinkBarRows } from "@/lib/infographic/drink-bars";
import type { RegionProductHit } from "@/lib/infographic/types";

type DrinkBarsChartProps = {
  products: RegionProductHit[];
  className?: string;
};

export function DrinkBarsChart({ products, className }: DrinkBarsChartProps) {
  const rows = buildDrinkBarRows(products);
  if (rows.length === 0) return null;

  return (
    <div className={className ?? "w-full max-w-xl"}>
      <ul className="flex flex-col gap-3" aria-label="Top drink mentions">
        {rows.map((row) => (
          <li key={row.name} className="grid grid-cols-[7rem_1fr_3rem] items-center gap-3">
            <span
              className={`truncate text-sm tracking-wide ${
                row.isLeader
                  ? "font-semibold text-foreground"
                  : "font-medium text-secondary"
              }`}
            >
              {row.name}
            </span>
            <div className="h-3 overflow-hidden rounded-sm bg-black/35">
              <div
                className="h-full rounded-sm"
                style={{
                  width: `${row.widthPercent}%`,
                  backgroundColor: row.color,
                }}
              />
            </div>
            <span
              className={`text-right text-sm tabular-nums ${
                row.isLeader ? "font-semibold text-accent-soft" : "text-muted"
              }`}
            >
              {row.percent}%
            </span>
          </li>
        ))}
      </ul>
    </div>
  );
}
