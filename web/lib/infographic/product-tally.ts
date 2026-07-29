import {
  expandKeywords,
  findMatchingProductsForDeals,
  type DealTextFields,
} from "@data/products";
import type { RegionProductHit } from "@/lib/infographic/types";

const DEFAULT_DEAL_SAMPLE_LIMIT = 500;

const DRINK_NAMES = new Set(
  expandKeywords(["drinks"]).map((name) => name.toLowerCase()),
);

const FOOD_NAMES = new Set(
  expandKeywords(["food"]).map((name) => name.toLowerCase()),
);

export type RegionProductCount = Omit<RegionProductHit, "percent">;

export type CategorizedProductHits = {
  drinks: RegionProductCount[];
  food: RegionProductCount[];
};

export function isDrinkProductName(name: string): boolean {
  return DRINK_NAMES.has(name.toLowerCase());
}

export function isFoodProductName(name: string): boolean {
  return FOOD_NAMES.has(name.toLowerCase());
}

function sortHits(counts: Map<string, RegionProductCount>): RegionProductCount[] {
  return [...counts.values()].sort((a, b) => {
    const countDiff = b.count - a.count;
    if (countDiff !== 0) return countDiff;
    return a.name.localeCompare(b.name);
  });
}

function bumpHit(
  counts: Map<string, RegionProductCount>,
  product: { name: string; icon?: string },
): void {
  const key = product.name.toLowerCase();
  const existing = counts.get(key);
  if (existing) {
    existing.count += 1;
    return;
  }
  counts.set(key, {
    name: product.name,
    icon: product.icon,
    count: 1,
  });
}

/** One-pass drink + food tallies from deal text (sample capped). */
export function tallyDrinkAndFoodHitsFromDeals(
  deals: DealTextFields[],
  limit = DEFAULT_DEAL_SAMPLE_LIMIT,
): CategorizedProductHits {
  const drinkCounts = new Map<string, RegionProductCount>();
  const foodCounts = new Map<string, RegionProductCount>();
  const sample = deals.slice(0, limit);

  for (const deal of sample) {
    const matches = findMatchingProductsForDeals([deal]);
    for (const product of matches) {
      if (isDrinkProductName(product.name)) {
        bumpHit(drinkCounts, product);
      }
      if (isFoodProductName(product.name)) {
        bumpHit(foodCounts, product);
      }
    }
  }

  return {
    drinks: sortHits(drinkCounts),
    food: sortHits(foodCounts),
  };
}

/** Drink-only tally (kept for tests and callers that only need drinks). */
export function tallyProductHitsFromDeals(
  deals: DealTextFields[],
  limit = DEFAULT_DEAL_SAMPLE_LIMIT,
): RegionProductCount[] {
  return tallyDrinkAndFoodHitsFromDeals(deals, limit).drinks;
}
