import productsJson from "./products.json";

export type Product = {
  name: string;
  rank?: number;
  groups?: string[];
  hidden?: boolean;
};

function mergeProducts(raw: Product[]): Product[] {
  const byName = new Map<string, Product>();

  for (const product of raw) {
    const key = product.name.toLowerCase();
    const existing = byName.get(key);

    if (!existing) {
      byName.set(key, {
        name: product.name,
        rank: product.rank,
        groups: product.groups ? [...new Set(product.groups)] : undefined,
        hidden: product.hidden,
      });
      continue;
    }

    const groups = [
      ...new Set([...(existing.groups ?? []), ...(product.groups ?? [])]),
    ];

    byName.set(key, {
      name: existing.name,
      rank: existing.rank ?? product.rank,
      groups: groups.length > 0 ? groups : undefined,
      hidden: existing.hidden || product.hidden,
    });
  }

  return [...byName.values()];
}

export const products: Product[] = mergeProducts(productsJson as Product[]);

const productsByName = new Map(
  products.map((product) => [product.name.toLowerCase(), product]),
);

function isExcluded(name: string, exclude: Set<string>): boolean {
  return exclude.has(name.toLowerCase());
}

function isVisible(product: Product): boolean {
  return !product.hidden;
}

export function getInitialSuggestions(exclude: Set<string> = new Set()): Product[] {
  return products
    .filter(
      (product) =>
        isVisible(product) &&
        product.rank !== undefined &&
        !isExcluded(product.name, exclude),
    )
    .sort((a, b) => (a.rank ?? 0) - (b.rank ?? 0));
}

export function filterSuggestions(
  input: string,
  exclude: Set<string> = new Set(),
): Product[] {
  const trimmed = input.trim().toLowerCase();
  if (!trimmed) {
    return getInitialSuggestions(exclude);
  }

  return products
    .filter(
      (product) =>
        isVisible(product) &&
        product.name.toLowerCase().includes(trimmed) &&
        !isExcluded(product.name, exclude),
    )
    .sort((a, b) => {
      const aRank = a.rank ?? Number.MAX_SAFE_INTEGER;
      const bRank = b.rank ?? Number.MAX_SAFE_INTEGER;
      if (aRank !== bRank) {
        return aRank - bRank;
      }
      return a.name.localeCompare(b.name);
    });
}

export function expandKeywords(tokens: string[]): string[] {
  const expanded = new Set<string>();

  for (const token of tokens) {
    const trimmed = token.trim();
    if (!trimmed) {
      continue;
    }

    expanded.add(trimmed);

    const product = productsByName.get(trimmed.toLowerCase());
    if (product?.groups) {
      for (const group of product.groups) {
        expanded.add(group);
      }
    }
  }

  return [...expanded];
}
