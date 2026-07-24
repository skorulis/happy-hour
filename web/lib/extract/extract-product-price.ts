import { findProductByName } from "@data/products";

const PRICE_PATTERN = /\$(\d+(?:\.\d{1,2})?)/g;

type ProductMatchTerm = {
  /** Substring to search for in deal text (already lowercased). */
  needle: string;
  /** Canonical product name to key the price under. */
  canonicalName: string;
};

function matchTermsForProducts(productNames: string[]): ProductMatchTerm[] {
  const terms: ProductMatchTerm[] = [];

  for (const name of productNames) {
    const canonicalName = name;
    const needles = new Set<string>([name.toLowerCase()]);
    const product = findProductByName(name);
    for (const synonym of product?.synonyms ?? []) {
      needles.add(synonym.toLowerCase());
    }
    for (const needle of needles) {
      terms.push({ needle, canonicalName });
    }
  }

  return terms;
}

function findFirstProductInSpan(
  text: string,
  start: number,
  end: number,
  matchTerms: ProductMatchTerm[],
): string | undefined {
  let bestName: string | undefined;
  let bestIndex = Number.POSITIVE_INFINITY;
  let bestNeedleLength = 0;

  for (const term of matchTerms) {
    const index = text.indexOf(term.needle, start);
    if (index === -1 || index >= end) {
      continue;
    }

    if (
      index < bestIndex ||
      (index === bestIndex && term.needle.length > bestNeedleLength)
    ) {
      bestIndex = index;
      bestNeedleLength = term.needle.length;
      bestName = term.canonicalName;
    }
  }

  return bestName;
}

function associatePricesInText(
  text: string,
  matchTerms: ProductMatchTerm[],
  pricesByName: Map<string, number>,
): void {
  if (!text || matchTerms.length === 0) {
    return;
  }

  const amounts: { value: number; end: number }[] = [];
  for (const match of text.matchAll(PRICE_PATTERN)) {
    const raw = match[1];
    if (raw === undefined || match.index === undefined) {
      continue;
    }
    amounts.push({
      value: Number(raw),
      end: match.index + match[0].length,
    });
  }

  for (const amount of amounts) {
    // Span runs from after this $amount to the start of the next $ (or EOF).
    const nextDollar = text.indexOf("$", amount.end);
    const end = nextDollar === -1 ? text.length : nextDollar;

    const productName = findFirstProductInSpan(
      text,
      amount.end,
      end,
      matchTerms,
    );
    if (!productName) {
      continue;
    }

    const key = productName.toLowerCase();
    if (!pricesByName.has(key)) {
      pricesByName.set(key, amount.value);
    }
  }
}

/**
 * Associates each matched product with the $amount that immediately precedes
 * it as the first catalog hit after that amount (until the next $).
 * Title and details are scanned separately so a title price cannot bind to a
 * product that only appears in details.
 * Synonyms from the product catalog are also searched and keyed to the
 * canonical product name.
 */
export function associatePricesWithProducts(
  title: string | null,
  details: string | null,
  productNames: string[],
): Map<string, number> {
  const pricesByName = new Map<string, number>();
  if (productNames.length === 0) {
    return pricesByName;
  }

  const matchTerms = matchTermsForProducts(productNames);

  associatePricesInText(
    (title ?? "").toLowerCase(),
    matchTerms,
    pricesByName,
  );
  associatePricesInText(
    (details ?? "").toLowerCase(),
    matchTerms,
    pricesByName,
  );

  return pricesByName;
}
