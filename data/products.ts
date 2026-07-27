import matchIgnoreJson from "./match-ignore.json";
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

export const productMatchIgnore: string[] = [
  ...new Set(matchIgnoreJson as string[]),
];

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

type TextRange = {
  start: number;
  end: number;
};

type MatchSpan = {
  productKey: string;
  start: number;
  end: number;
};

function collectSubstringRanges(text: string, needles: string[]): TextRange[] {
  const ranges: TextRange[] = [];

  for (const needle of needles) {
    const n = needle.toLowerCase();
    if (!n) {
      continue;
    }
    let from = 0;
    while (from <= text.length) {
      const idx = text.indexOf(n, from);
      if (idx === -1) {
        break;
      }
      ranges.push({ start: idx, end: idx + n.length });
      from = idx + 1;
    }
  }

  return ranges;
}

/** "With …" / "w/ …" describes sides/add-ons, not the product — ignore through end of line. */
function collectWithClauseIgnoreRanges(text: string): TextRange[] {
  const ranges: TextRange[] = [];
  const pattern = /\b(?:with|w\/)[^\n]*/g;
  let match: RegExpExecArray | null;
  while ((match = pattern.exec(text)) !== null) {
    ranges.push({ start: match.index, end: match.index + match[0].length });
  }
  return ranges;
}

function collectIgnoreRanges(text: string): TextRange[] {
  return [
    ...collectSubstringRanges(text, productMatchIgnore),
    ...collectWithClauseIgnoreRanges(text),
  ];
}

function isRangeCovered(range: TextRange, covers: TextRange[]): boolean {
  return covers.some(
    (cover) => range.start >= cover.start && range.end <= cover.end,
  );
}

function collectMatchSpans(
  text: string,
  product: Product,
  ignoreRanges: TextRange[],
): MatchSpan[] {
  const productKey = product.name.toLowerCase();
  const needles = [product.name, ...(product.synonyms ?? [])];

  return collectSubstringRanges(text, needles)
    .filter((range) => !isRangeCovered(range, ignoreRanges))
    .map((range) => ({ productKey, ...range }));
}

function findProductsMatchingText(text: string): Product[] {
  if (!text) {
    return [];
  }

  const ignoreRanges = collectIgnoreRanges(text);
  const matches = productsWithIcons.filter(
    (product) => collectMatchSpans(text, product, ignoreRanges).length > 0,
  );

  return [...matches].sort(compareProductMatches);
}

function suppressOverlappingMatches(
  text: string,
  matches: Product[],
): Product[] {
  if (matches.length <= 1) {
    return matches;
  }

  const ignoreRanges = collectIgnoreRanges(text);
  const spans = matches.flatMap((product) =>
    collectMatchSpans(text, product, ignoreRanges),
  );
  spans.sort(
    (a, b) => b.end - b.start - (a.end - a.start) || a.start - b.start,
  );

  const acceptedSpans: MatchSpan[] = [];
  const acceptedProducts = new Set<string>();

  for (const span of spans) {
    const covered = acceptedSpans.some(
      (accepted) => span.start >= accepted.start && span.end <= accepted.end,
    );
    if (covered) {
      continue;
    }
    acceptedSpans.push(span);
    acceptedProducts.add(span.productKey);
  }

  return matches.filter((product) =>
    acceptedProducts.has(product.name.toLowerCase()),
  );
}

export function findMatchingProductsForDeals(
  deals: DealTextFields[],
): Product[] {
  const titleText = dealTitleText(deals);
  const titleMatches = suppressOverlappingMatches(
    titleText,
    findProductsMatchingText(titleText),
  );
  if (titleMatches.length > 0) {
    return titleMatches;
  }
  const detailsText = dealDetailsText(deals);
  return suppressOverlappingMatches(
    detailsText,
    findProductsMatchingText(detailsText),
  );
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

function titleMatchesBottomless(deals: DealTextFields[]): boolean {
  return findProductsMatchingText(dealTitleText(deals)).some(
    (product) => product.name.toLowerCase() === "bottomless",
  );
}

function matchProductsInText(text: string): Product[] {
  return suppressOverlappingMatches(text, findProductsMatchingText(text));
}

const PRODUCT_MATCH_RULES_V2: ProductMatchRuleV2[] = [
  {
    id: "bottomless-title-only",
    apply: (deals) => {
      if (!titleMatchesBottomless(deals)) {
        return [];
      }
      return matchProductsInText(dealTitleText(deals));
    },
  },
  {
    id: "combined-substring",
    apply: (deals) => {
      if (titleMatchesBottomless(deals)) {
        return [];
      }
      return matchProductsInText(dealTitleAndDetailsText(deals));
    },
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
