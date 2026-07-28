import { findProductByName } from "@data/products";

const PRICE_PATTERN = /\$(\d+(?:\.\d{1,2})?)/g;

/**
 * List joiners between products that share one `$` amount
 * (`$5 beer and house wine`, `$5 beer, wine and cocktails`).
 */
const LIST_SEPARATOR = /^\s*(?:,\s*(?:and\s+)?|&\s*|and\s+)/;

/** True when `$N` is a discount amount, not an item price (e.g. "$10 off"). */
function isDiscountAmount(text: string, start: number, end: number): boolean {
  // "$10 off ...", "$5 discount", "$5 savings"
  if (/^\s*(?:off|discount|savings?)\b/.test(text.slice(end))) {
    return true;
  }
  // "save $10 ...", "save up to $10 ..."
  if (/\bsave(?:\s+up\s+to)?\s*$/.test(text.slice(0, start))) {
    return true;
  }
  return false;
}

type ProductMatchTerm = {
  /** Substring to search for in deal text (already lowercased). */
  needle: string;
  /** Canonical product name to key the price under. */
  canonicalName: string;
};

type ProductHit = {
  canonicalName: string;
  start: number;
  end: number;
};

function matchTermsForProducts(productNames: string[]): ProductMatchTerm[] {
  const terms: ProductMatchTerm[] = [];

  for (const name of productNames) {
    const product = findProductByName(name);
    if (product?.noprice) {
      continue;
    }
    const canonicalName = name;
    const needles = new Set<string>([name.toLowerCase()]);
    for (const synonym of product?.synonyms ?? []) {
      needles.add(synonym.toLowerCase());
    }
    for (const needle of needles) {
      terms.push({ needle, canonicalName });
    }
  }

  return terms;
}

/** Extend a needle match past a simple plural suffix (`beer` → `beers`). */
function endWithOptionalPlural(
  text: string,
  start: number,
  needleLength: number,
): number {
  const end = start + needleLength;
  if (text.startsWith("es", end) && !/[a-z0-9]/i.test(text[end + 2] ?? "")) {
    return end + 2;
  }
  if (text.startsWith("s", end) && !/[a-z0-9]/i.test(text[end + 1] ?? "")) {
    return end + 1;
  }
  return end;
}

function findFirstProductInSpan(
  text: string,
  start: number,
  end: number,
  matchTerms: ProductMatchTerm[],
): ProductHit | undefined {
  let best: ProductHit | undefined;
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
      best = {
        canonicalName: term.canonicalName,
        start: index,
        end: endWithOptionalPlural(text, index, term.needle.length),
      };
    }
  }

  return best;
}

/** Last (rightmost) catalog hit in [start, end), preferring the longer needle on ties. */
function findLastProductInSpan(
  text: string,
  start: number,
  end: number,
  matchTerms: ProductMatchTerm[],
): string | undefined {
  let bestName: string | undefined;
  let bestEnd = Number.NEGATIVE_INFINITY;
  let bestNeedleLength = 0;

  for (const term of matchTerms) {
    let from = start;
    while (from < end) {
      const index = text.indexOf(term.needle, from);
      if (index === -1 || index >= end) {
        break;
      }
      const matchEnd = endWithOptionalPlural(text, index, term.needle.length);
      if (
        matchEnd > bestEnd ||
        (matchEnd === bestEnd && term.needle.length > bestNeedleLength)
      ) {
        bestEnd = matchEnd;
        bestNeedleLength = term.needle.length;
        bestName = term.canonicalName;
      }
      from = index + 1;
    }
  }

  return bestName;
}

/** Catalog needle that begins exactly at `pos` (longest wins). */
function findProductStartingAt(
  text: string,
  pos: number,
  end: number,
  matchTerms: ProductMatchTerm[],
): ProductHit | undefined {
  let best: ProductHit | undefined;
  let bestNeedleLength = 0;

  for (const term of matchTerms) {
    if (pos + term.needle.length > end) {
      continue;
    }
    if (!text.startsWith(term.needle, pos)) {
      continue;
    }
    if (term.needle.length > bestNeedleLength) {
      bestNeedleLength = term.needle.length;
      best = {
        canonicalName: term.canonicalName,
        start: pos,
        end: endWithOptionalPlural(text, pos, term.needle.length),
      };
    }
  }

  return best;
}

/**
 * First catalog hit after `$`, plus later hits joined only by `,` / `&` / `and`.
 * Stops at the next `$`, or when the next token is not a list separator + product.
 */
function collectProductsInPriceList(
  text: string,
  spanStart: number,
  spanEnd: number,
  matchTerms: ProductMatchTerm[],
): string[] {
  const first = findFirstProductInSpan(text, spanStart, spanEnd, matchTerms);
  if (!first) {
    return [];
  }

  const names: string[] = [first.canonicalName];
  let cursor = first.end;

  while (cursor < spanEnd) {
    const rest = text.slice(cursor, spanEnd);
    const sep = rest.match(LIST_SEPARATOR);
    if (!sep) {
      break;
    }
    cursor += sep[0].length;

    const next = findProductStartingAt(text, cursor, spanEnd, matchTerms);
    if (!next) {
      break;
    }
    names.push(next.canonicalName);
    cursor = next.end;
  }

  return names;
}

function setPriceIfAbsent(
  pricesByName: Map<string, number>,
  productName: string,
  value: number,
): void {
  const key = productName.toLowerCase();
  if (!pricesByName.has(key)) {
    pricesByName.set(key, value);
  }
}

function associatePricesInText(
  text: string,
  matchTerms: ProductMatchTerm[],
  pricesByName: Map<string, number>,
): void {
  if (!text || matchTerms.length === 0) {
    return;
  }

  const amounts: { value: number; start: number; end: number }[] = [];
  for (const match of text.matchAll(PRICE_PATTERN)) {
    const raw = match[1];
    if (raw === undefined || match.index === undefined) {
      continue;
    }
    const start = match.index;
    const end = match.index + match[0].length;
    if (isDiscountAmount(text, start, end)) {
      continue;
    }
    amounts.push({
      value: Number(raw),
      start,
      end,
    });
  }

  for (let i = 0; i < amounts.length; i++) {
    const amount = amounts[i]!;
    // Prefer "$8 beers": catalog hits after this amount until the next $.
    const nextDollar = text.indexOf("$", amount.end);
    const afterEnd = nextDollar === -1 ? text.length : nextDollar;

    const listed = collectProductsInPriceList(
      text,
      amount.end,
      afterEnd,
      matchTerms,
    );

    if (listed.length > 0) {
      for (const productName of listed) {
        setPriceIfAbsent(pricesByName, productName, amount.value);
      }
      continue;
    }

    // Fallback for "Happy Hour $8" / "Fish & chips $18": nearest product before $.
    const prevEnd = i > 0 ? amounts[i - 1]!.end : 0;
    const productName = findLastProductInSpan(
      text,
      prevEnd,
      amount.start,
      matchTerms,
    );

    if (!productName) {
      continue;
    }

    setPriceIfAbsent(pricesByName, productName, amount.value);
  }
}

/**
 * Associates each matched product with a nearby $amount: prefers catalog hits
 * after that amount (until the next $), including products joined by
 * `and` / `&` / `,` (e.g. "$5 beer and house wine"), otherwise the nearest
 * catalog hit before it (after the previous $). Covers both "$8 beers" and
 * "Happy Hour $8". Discount amounts ("$10 off", "save $5") are skipped.
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
