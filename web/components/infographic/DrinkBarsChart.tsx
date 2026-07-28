import { ProductMapIcon, isRegisteredProductIcon } from "@/lib/search/ProductMapIcon";
import { buildDrinkBarRows } from "@/lib/infographic/drink-bars";
import type { RegionProductHit } from "@/lib/infographic/types";

type DrinkBarsChartProps = {
  products: RegionProductHit[];
  className?: string;
};

function DrinkIconStrip({
  icon,
  color,
  count,
}: {
  icon?: string;
  color: string;
  count: number;
}) {
  const iconName =
    icon && isRegisteredProductIcon(icon) ? icon : "Beer";

  return (
    <div
      className="flex flex-wrap items-center gap-0.5"
      style={{ color }}
      aria-hidden
    >
      {Array.from({ length: count }, (_, index) => (
        <ProductMapIcon
          key={`${iconName}-${index}`}
          name={iconName}
          size={18}
          className="shrink-0"
        />
      ))}
    </div>
  );
}

export function DrinkBarsChart({ products, className }: DrinkBarsChartProps) {
  const rows = buildDrinkBarRows(products);
  if (rows.length === 0) return null;

  return (
    <div className={className ?? "w-full max-w-2xl"}>
      <ul className="flex flex-col gap-3.5" aria-label="Top drink mentions">
        {rows.map((row) => (
          <li
            key={row.name}
            className="grid grid-cols-[7rem_1fr_3rem] items-center gap-3"
          >
            <span
              className={`truncate text-sm tracking-wide capitalize ${
                row.isLeader
                  ? "font-semibold text-foreground"
                  : "font-medium text-secondary"
              }`}
            >
              {row.name}
            </span>
            <DrinkIconStrip
              icon={row.icon}
              color={row.color}
              count={row.iconCount}
            />
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
