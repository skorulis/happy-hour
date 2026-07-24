import productsJson from "./products.json";

export type Product = {
  name: string;
  rank?: number;
  groups?: string[];
  synonyms?: string[];
  hidden?: boolean;
  icon?: string;
};

export type DealTextFields = {
  title: string | null;
  details: string | null;
  conditions: string | null;
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
        synonyms: product.synonyms ? [...new Set(product.synonyms)] : undefined,
        hidden: product.hidden,
        icon: product.icon,
      });
      continue;
    }

    const groups = [
      ...new Set([...(existing.groups ?? []), ...(product.groups ?? [])]),
    ];
    const synonyms = [
      ...new Set([...(existing.synonyms ?? []), ...(product.synonyms ?? [])]),
    ];

    byName.set(key, {
      name: existing.name,
      rank: existing.rank ?? product.rank,
      groups: groups.length > 0 ? groups : undefined,
      synonyms: synonyms.length > 0 ? synonyms : undefined,
      hidden: existing.hidden || product.hidden,
      icon: existing.icon ?? product.icon,
    });
  }

  return [...byName.values()];
}

export const products: Product[] = mergeProducts(productsJson as Product[]);

const productsByName = new Map(
  products.map((product) => [product.name.toLowerCase(), product]),
);

const productsWithIcons = products.filter(
  (product): product is Product & { icon: string } => !!product.icon,
);

function isExcluded(name: string, exclude: Set<string>): boolean {
  return exclude.has(name.toLowerCase());
}

function isVisible(product: Product): boolean {
  return !product.hidden;
}

function dealTitleText(deals: DealTextFields[]): string {
  return deals
    .map((deal) => deal.title)
    .filter(Boolean)
    .join(" ")
    .toLowerCase();
}

function dealDetailsText(deals: DealTextFields[]): string {
  return deals
    .map((deal) => deal.details)
    .filter(Boolean)
    .join(" ")
    .toLowerCase();
}

function compareProductMatches(a: Product, b: Product): number {
  const aRank = a.rank ?? Number.MAX_SAFE_INTEGER;
  const bRank = b.rank ?? Number.MAX_SAFE_INTEGER;
  if (aRank !== bRank) {
    return aRank - bRank;
  }
  return b.name.length - a.name.length;
}

function findProductsMatchingText(text: string): Product[] {
  if (!text) {
    return [];
  }

  const matches = productsWithIcons.filter((product) => {
    if (text.includes(product.name.toLowerCase())) {
      return true;
    }
    return (product.synonyms ?? []).some((synonym) =>
      text.includes(synonym.toLowerCase()),
    );
  });

  return [...matches].sort(compareProductMatches);
}

export function findMatchingProductsForDeals(
  deals: DealTextFields[],
): Product[] {
  const titleMatches = findProductsMatchingText(dealTitleText(deals));
  if (titleMatches.length > 0) {
    return titleMatches;
  }
  return findProductsMatchingText(dealDetailsText(deals));
}

type ProductMatchRuleV2 = {
  id: string;
  apply: (deals: DealTextFields[]) => Product[];
};

function dealTitleAndDetailsText(deals: DealTextFields[]): string {
  return [dealTitleText(deals), dealDetailsText(deals)]
    .filter(Boolean)
    .join(" ");
}

const PRODUCT_MATCH_RULES_V2: ProductMatchRuleV2[] = [
  {
    id: "combined-substring",
    apply: (deals) => findProductsMatchingText(dealTitleAndDetailsText(deals)),
  },
];

export function findMatchingProductsForDealsV2(
  deals: DealTextFields[],
): Product[] {
  const byName = new Map<string, Product>();

  for (const rule of PRODUCT_MATCH_RULES_V2) {
    for (const product of rule.apply(deals)) {
      byName.set(product.name.toLowerCase(), product);
    }
  }

  return [...byName.values()].sort(compareProductMatches);
}

export function resolveMapIconForDeals(
  deals: DealTextFields[],
): string | undefined {
  return findMatchingProductsForDeals(deals)[0]?.icon;
}

export function findProductByName(name: string): Product | undefined {
  return productsByName.get(name.toLowerCase());
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
        !isExcluded(product.name, exclude) &&
        (product.name.toLowerCase().includes(trimmed) ||
          (product.synonyms ?? []).some((synonym) =>
            synonym.toLowerCase().includes(trimmed),
          )),
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
  const expanded: string[] = [];
  const seen = new Set<string>();
  const queue = tokens
    .map((token) => token.trim())
    .filter((token) => token.length > 0);

  while (queue.length > 0) {
    const token = queue.shift()!;
    const key = token.toLowerCase();
    if (seen.has(key)) {
      continue;
    }

    seen.add(key);
    expanded.push(token);

    const product = productsByName.get(key);
    if (product?.groups) {
      for (const group of product.groups) {
        queue.push(group);
      }
    }
  }

  return expanded;
}

export function expandKeywordGroups(tokens: string[]): string[][] {
  return tokens
    .map((token) => token.trim())
    .filter((token) => token.length > 0)
    .map((token) => expandKeywords([token]));
}
