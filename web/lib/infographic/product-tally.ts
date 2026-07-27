import {
  findMatchingProductsForDeals,
  type DealTextFields,
} from "@data/products";
import type { RegionProductHit } from "@/lib/infographic/types";

const DEFAULT_DEAL_SAMPLE_LIMIT = 500;

export function tallyProductHitsFromDeals(
  deals: DealTextFields[],
  limit = DEFAULT_DEAL_SAMPLE_LIMIT,
): RegionProductHit[] {
  const counts = new Map<string, RegionProductHit>();
  const sample = deals.slice(0, limit);

  for (const deal of sample) {
    const matches = findMatchingProductsForDeals([deal]);
    for (const product of matches) {
      const key = product.name.toLowerCase();
      const existing = counts.get(key);
      if (existing) {
        existing.count += 1;
        continue;
      }
      counts.set(key, {
        name: product.name,
        icon: product.icon,
        count: 1,
      });
    }
  }

  return [...counts.values()].sort((a, b) => {
    const countDiff = b.count - a.count;
    if (countDiff !== 0) return countDiff;
    return a.name.localeCompare(b.name);
  });
}
