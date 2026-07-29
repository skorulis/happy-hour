import { ProductMapIcon, isRegisteredProductIcon } from "@/lib/search/ProductMapIcon";
import { buildDrinkBarRows } from "@/lib/infographic/drink-bars";
import type { RegionProductHit } from "@/lib/infographic/types";

type ProductBarsChartProps = {
  products: RegionProductHit[];
  className?: string;
  ariaLabel?: string;
  /** Fallback when a product has no registered icon (drinks → Beer, food → UtensilsCrossed). */
  fallbackIcon?: string;
};

function ProductIconStrip({
  icon,
  color,
  count,
  fallbackIcon,
}: {
  icon?: string;
  color: string;
  count: number;
  fallbackIcon: string;
}) {
  const iconName =
    icon && isRegisteredProductIcon(icon) ? icon : fallbackIcon;

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

export function ProductBarsChart({
  products,
  className,
  ariaLabel = "Top product mentions",
  fallbackIcon = "Beer",
}: ProductBarsChartProps) {
  const rows = buildDrinkBarRows(products);
  if (rows.length === 0) return null;

  return (
    <div className={className ?? "w-full max-w-2xl"}>
      <ul className="flex flex-col gap-3.5" aria-label={ariaLabel}>
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
            <ProductIconStrip
              icon={row.icon}
              color={row.color}
              count={row.iconCount}
              fallbackIcon={fallbackIcon}
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

export function DrinkBarsChart(
  props: Omit<ProductBarsChartProps, "ariaLabel" | "fallbackIcon"> & {
    ariaLabel?: string;
    fallbackIcon?: string;
  },
) {
  return (
    <ProductBarsChart
      ariaLabel="Top drink mentions"
      fallbackIcon="Beer"
      {...props}
    />
  );
}
