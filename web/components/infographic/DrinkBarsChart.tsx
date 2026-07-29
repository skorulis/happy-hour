import { ProductMapIcon, isRegisteredProductIcon } from "@/lib/search/ProductMapIcon";
import { buildDrinkBarRows } from "@/lib/infographic/drink-bars";
import type { RegionProductHit } from "@/lib/infographic/types";

type ProductBarsChartProps = {
  products: RegionProductHit[];
  className?: string;
  ariaLabel?: string;
  /** Fallback when a product has no registered icon (drinks → Beer, food → UtensilsCrossed). */
  fallbackIcon?: string;
  /** Tighter rows / fewer icons for side-by-side layout. */
  dense?: boolean;
};

function ProductIconStrip({
  icon,
  color,
  count,
  fallbackIcon,
  size,
}: {
  icon?: string;
  color: string;
  count: number;
  fallbackIcon: string;
  size: number;
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
          size={size}
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
  dense = false,
}: ProductBarsChartProps) {
  const rows = buildDrinkBarRows(products, {
    maxIcons: dense ? 6 : 12,
  });
  if (rows.length === 0) return null;

  return (
    <div className={className ?? (dense ? "w-full" : "w-full max-w-2xl")}>
      <ul
        className={`flex flex-col ${dense ? "gap-2" : "gap-3.5"}`}
        aria-label={ariaLabel}
      >
        {rows.map((row) => (
          <li
            key={row.name}
            className={
              dense
                ? "flex items-center gap-2"
                : "grid grid-cols-[7rem_1fr_3rem] items-center gap-3"
            }
          >
            <span
              className={`shrink-0 truncate tracking-wide capitalize ${
                dense ? "w-[4.5rem] text-xs" : "text-sm"
              } ${
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
              size={dense ? 14 : 18}
            />
            <span
              className={`text-right tabular-nums ${
                dense ? "ml-auto text-xs" : "text-sm"
              } ${
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
