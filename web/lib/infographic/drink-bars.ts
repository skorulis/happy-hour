import type { RegionProductCount } from "@/lib/infographic/product-tally";
import type { RegionProductHit } from "@/lib/infographic/types";

/** Amber SRM ramp for ranks 1→5 (leader = deepest amber). */
export const DRINK_BAR_COLORS = [
  "#a63e00", // Amber Brown ~SRM 18
  "#bb5100", // Deep Amber ~SRM 15
  "#cf6900", // Medium Amber ~SRM 12
  "#e58500", // Pale Amber ~SRM 9
  "#f8a600", // Deep Gold ~SRM 6
] as const;

export const TOP_DRINK_LIMIT = 5;

/**
 * Largest-remainder percentages over the full hit list (sums to 100 when
 * total count > 0). Then keep the top N for the chart.
 */
export function rankTopProductHits(
  hits: RegionProductCount[],
  limit = TOP_DRINK_LIMIT,
): RegionProductHit[] {
  if (hits.length === 0) return [];

  const total = hits.reduce((sum, hit) => sum + hit.count, 0);
  if (total <= 0) {
    return hits.slice(0, limit).map((hit) => ({ ...hit, percent: 0 }));
  }

  const raw = hits.map((hit) => ({
    ...hit,
    exact: (hit.count / total) * 100,
  }));
  const floored = raw.map((hit) => ({
    ...hit,
    percent: Math.floor(hit.exact),
    fraction: hit.exact - Math.floor(hit.exact),
  }));
  let remainder = 100 - floored.reduce((sum, hit) => sum + hit.percent, 0);
  const byFraction = [...floored].sort((a, b) => {
    const fractionDiff = b.fraction - a.fraction;
    if (fractionDiff !== 0) return fractionDiff;
    return a.name.localeCompare(b.name);
  });
  for (const hit of byFraction) {
    if (remainder <= 0) break;
    if (hit.count <= 0) continue;
    hit.percent += 1;
    remainder -= 1;
  }
  if (remainder > 0) {
    const peak = byFraction.find((hit) => hit.count > 0) ?? byFraction[0];
    if (peak) peak.percent += remainder;
  }

  return floored.slice(0, limit).map((hit) => ({
    name: hit.name,
    icon: hit.icon,
    count: hit.count,
    percent: hit.percent,
  }));
}

export const rankTopDrinkHits = rankTopProductHits;

/** Bar fill width as percent of the leader’s count (leader = 100). */
export function barWidthPercent(count: number, maxCount: number): number {
  if (maxCount <= 0 || count <= 0) return 0;
  return Math.max(0, Math.min(100, (count / maxCount) * 100));
}

export function drinkBarColor(rankIndex: number): string {
  return (
    DRINK_BAR_COLORS[Math.min(rankIndex, DRINK_BAR_COLORS.length - 1)] ??
    DRINK_BAR_COLORS[0]!
  );
}

export type DrinkBarRow = RegionProductHit & {
  color: string;
  widthPercent: number;
  iconCount: number;
  isLeader: boolean;
};

/** How many icons the leader’s bar uses; others scale by relative count. */
export const DRINK_BAR_MAX_ICONS = 12;

export function iconCountForWidth(
  widthPercent: number,
  maxIcons = DRINK_BAR_MAX_ICONS,
): number {
  if (widthPercent <= 0 || maxIcons <= 0) return 0;
  return Math.max(1, Math.round((widthPercent / 100) * maxIcons));
}

export function buildDrinkBarRows(
  products: RegionProductHit[],
  options?: { maxIcons?: number },
): DrinkBarRow[] {
  const maxIcons = options?.maxIcons ?? DRINK_BAR_MAX_ICONS;
  const maxCount = products.reduce(
    (max, product) => Math.max(max, product.count),
    0,
  );
  return products.map((product, index) => {
    const widthPercent = barWidthPercent(product.count, maxCount);
    return {
      ...product,
      color: drinkBarColor(index),
      widthPercent,
      iconCount: iconCountForWidth(widthPercent, maxIcons),
      isLeader: index === 0,
    };
  });
}

