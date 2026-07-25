import { products } from "@/data/products";
import {
  dayNumberToPathSlug,
  pathSlugToDayNumber,
  stripDaySuffix,
} from "@/lib/search/day-path";

/** Compact a what token for path encoding: lowercase, strip non-alphanumeric. */
export function whatSlug(token: string): string {
  return token
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "");
}

function buildWhatSlugToCanonical(): ReadonlyMap<string, string> {
  const map = new Map<string, string>();

  for (const product of products) {
    const canonical = product.name;
    const nameSlug = whatSlug(canonical);
    if (nameSlug && !map.has(nameSlug)) {
      map.set(nameSlug, canonical);
    }
    for (const synonym of product.synonyms ?? []) {
      const synonymSlug = whatSlug(synonym);
      if (synonymSlug && !map.has(synonymSlug)) {
        map.set(synonymSlug, canonical);
      }
    }
  }

  return map;
}

const WHAT_SLUG_TO_CANONICAL = buildWhatSlugToCanonical();

/** Resolve a path what slug to the canonical product name, or null if unknown. */
export function pathSlugToWhatToken(slug: string): string | null {
  const compact = whatSlug(slug);
  if (!compact) {
    return null;
  }
  return WHAT_SLUG_TO_CANONICAL.get(compact) ?? null;
}

export type SplitWhatForPath = {
  pathTokens: string[];
  queryTokens: string[];
};

/**
 * Split what tokens into catalog tokens (path-safe) and free-text (stay in `?q=`).
 * Path tokens are canonical product names; order is preserved.
 */
export function splitWhatForPath(what: string[]): SplitWhatForPath {
  const pathTokens: string[] = [];
  const queryTokens: string[] = [];

  for (const token of what) {
    const trimmed = token.trim();
    if (!trimmed) {
      continue;
    }
    const canonical = pathSlugToWhatToken(trimmed);
    if (canonical !== null) {
      pathTokens.push(canonical);
    } else {
      queryTokens.push(trimmed);
    }
  }

  return { pathTokens, queryTokens };
}

export type ParsedFilterSegment = {
  day: number | null;
  what: string[];
};

/**
 * Encode day + catalog what tokens into a single path segment
 * (`wednesday-beer-happyhour`, `cocktails`, `wednesday`).
 * Returns null when both are empty.
 */
export function encodeFilterSegment(
  day: number | null,
  what: string[],
): string | null {
  const parts: string[] = [];

  if (day !== null) {
    const daySlug = dayNumberToPathSlug(day);
    if (daySlug) {
      parts.push(daySlug);
    }
  }

  for (const token of what) {
    const slug = whatSlug(token);
    if (slug) {
      parts.push(slug);
    }
  }

  return parts.length > 0 ? parts.join("-") : null;
}

/**
 * Parse a path segment as a day/what filter.
 * A segment is a filter when the first hyphen-part is a day slug and every
 * remaining part is a known what slug (or empty), OR every part is a known
 * what slug. Venue-like segments (`the-local`) return null.
 */
export function parseFilterSegment(segment: string): ParsedFilterSegment | null {
  const trimmed = segment.trim().toLowerCase();
  if (!trimmed) {
    return null;
  }

  const parts = trimmed.split("-").filter((part) => part.length > 0);
  if (parts.length === 0) {
    return null;
  }

  let day: number | null = null;
  let whatParts = parts;

  const firstDay = pathSlugToDayNumber(parts[0]!);
  if (firstDay !== null) {
    day = firstDay;
    whatParts = parts.slice(1);
  }

  const what: string[] = [];
  for (const part of whatParts) {
    const token = pathSlugToWhatToken(part);
    if (token === null) {
      return null;
    }
    what.push(token);
  }

  if (day === null && what.length === 0) {
    return null;
  }

  return { day, what };
}

export type StrippedFiltersPath = {
  base: string;
  day: number | null;
  what: string[];
};

function splitPathTrailing(path: string): {
  pathOnly: string;
  trailing: string;
} {
  const hashIndex = path.indexOf("#");
  const queryIndex = path.indexOf("?");
  let suffixStart = path.length;
  if (hashIndex >= 0) {
    suffixStart = Math.min(suffixStart, hashIndex);
  }
  if (queryIndex >= 0) {
    suffixStart = Math.min(suffixStart, queryIndex);
  }
  return {
    pathOnly: path.slice(0, suffixStart),
    trailing: path.slice(suffixStart),
  };
}

/**
 * Removes a trailing filter segment (`/wednesday-beer`, `/cocktails`) and any
 * legacy `-{day}` suffixes. The sole segment of a path is never treated as a
 * filter segment (it is the where slug).
 */
export function stripFiltersFromPath(pathname: string): StrippedFiltersPath {
  const segments = pathname.split("/").filter(Boolean);
  if (segments.length === 0) {
    return { base: "/", day: null, what: [] };
  }

  let day: number | null = null;
  let what: string[] = [];
  const working = [...segments];

  if (working.length >= 2) {
    const parsed = parseFilterSegment(working[working.length - 1]!);
    if (parsed) {
      day = parsed.day;
      what = parsed.what;
      working.pop();
    }
  }

  const rewritten = working.map((segment) => {
    const stripped = stripDaySuffix(segment);
    if (stripped.day !== null && day === null) {
      day = stripped.day;
    }
    return stripped.base;
  });

  return {
    base: rewritten.length === 0 ? "/" : `/${rewritten.join("/")}`,
    day,
    what,
  };
}

/**
 * Appends a filter segment (`/{day}-{what…}`) when day and/or catalog what
 * tokens are selected. Always strips an existing filter segment first.
 * `/` and `/map` never gain a filter segment.
 */
export function appendFiltersToPath(
  path: string,
  days: number[],
  what: string[] = [],
): string {
  const { pathOnly, trailing } = splitPathTrailing(path);
  if (pathOnly === "/" || pathOnly === "") {
    return `${pathOnly || "/"}${trailing}`;
  }

  const { base } = stripFiltersFromPath(pathOnly);
  if (base === "/map") {
    return `/map${trailing}`;
  }

  const day = days.length === 1 ? days[0]! : null;
  const { pathTokens } = splitWhatForPath(what);
  const segment = encodeFilterSegment(day, pathTokens);
  if (!segment) {
    return `${base}${trailing}`;
  }

  return `${base}/${segment}${trailing}`;
}
