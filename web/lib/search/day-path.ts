/** Lowercase full weekday names used as path suffixes (`monday`, …). */
export const DAY_PATH_SLUGS: Readonly<Record<number, string>> = {
  1: "sunday",
  2: "monday",
  3: "tuesday",
  4: "wednesday",
  5: "thursday",
  6: "friday",
  7: "saturday",
};

const PATH_SLUG_TO_DAY: Readonly<Record<string, number>> = Object.fromEntries(
  Object.entries(DAY_PATH_SLUGS).map(([day, slug]) => [slug, Number(day)]),
);

const DAY_SUFFIX_RE = new RegExp(
  `-(${Object.values(DAY_PATH_SLUGS).join("|")})$`,
);

export function dayNumberToPathSlug(day: number): string | null {
  return DAY_PATH_SLUGS[day] ?? null;
}

export function pathSlugToDayNumber(slug: string): number | null {
  return PATH_SLUG_TO_DAY[slug.trim().toLowerCase()] ?? null;
}

export type StrippedDaySuffix = {
  base: string;
  day: number | null;
};

/**
 * Strips a trailing weekday slug (`-monday`, …) from a single path segment.
 * Only known day names are stripped so postcodes and other suffixes stay intact.
 */
export function stripDaySuffix(slug: string): StrippedDaySuffix {
  const trimmed = slug.trim().toLowerCase();
  const match = DAY_SUFFIX_RE.exec(trimmed);
  if (!match) {
    return { base: trimmed, day: null };
  }
  const daySlug = match[1]!;
  const day = PATH_SLUG_TO_DAY[daySlug] ?? null;
  const base = trimmed.slice(0, match.index);
  if (!base) {
    return { base: trimmed, day: null };
  }
  return { base, day };
}

/**
 * Appends `-{day}` to the last path segment when exactly one day is selected.
 * Always strips an existing day suffix first so clearing the filter returns the base path.
 */
export function appendDayToPath(path: string, days: number[]): string {
  const hashIndex = path.indexOf("#");
  const queryIndex = path.indexOf("?");
  let suffixStart = path.length;
  if (hashIndex >= 0) {
    suffixStart = Math.min(suffixStart, hashIndex);
  }
  if (queryIndex >= 0) {
    suffixStart = Math.min(suffixStart, queryIndex);
  }

  const pathOnly = path.slice(0, suffixStart);
  const trailing = path.slice(suffixStart);
  if (pathOnly === "/" || pathOnly === "") {
    return `${pathOnly || "/"}${trailing}`;
  }

  const segments = pathOnly.split("/");
  const lastIndex = segments.length - 1;
  const last = segments[lastIndex] ?? "";
  if (!last) {
    return path;
  }

  const { base } = stripDaySuffix(last);
  if (days.length !== 1) {
    segments[lastIndex] = base;
    return `${segments.join("/")}${trailing}`;
  }

  const daySlug = dayNumberToPathSlug(days[0]!);
  if (!daySlug) {
    segments[lastIndex] = base;
    return `${segments.join("/")}${trailing}`;
  }

  segments[lastIndex] = `${base}-${daySlug}`;
  return `${segments.join("/")}${trailing}`;
}

function parseLegacySingleDayParam(value: string | null): number[] {
  if (value === null || value.trim() === "") {
    return [];
  }
  const days = value
    .split(",")
    .map((part) => Number(part.trim()))
    .filter((day) => Number.isFinite(day) && day >= 1 && day <= 7);
  return days.length === 1 ? days : [];
}

/**
 * Days from a browser URL: prefer path suffix; fall back to legacy `?days=`
 * (used for redirects). Multi-day query values collapse to empty.
 */
export function daysFromBrowserUrl(
  pathname: string,
  searchParams?: URLSearchParams | { get(name: string): string | null },
): number[] {
  const segments = pathname.split("/").filter(Boolean);
  for (const segment of segments) {
    const { day } = stripDaySuffix(segment);
    if (day !== null) {
      return [day];
    }
  }

  if (!searchParams) {
    return [];
  }
  return parseLegacySingleDayParam(searchParams.get("days"));
}

/** `#monday` for a calendar weekday, or null when invalid. */
export function dayNumberToHash(day: number): string | null {
  const slug = dayNumberToPathSlug(day);
  return slug ? `#${slug}` : null;
}

/** Parse `#monday` or `monday` into a calendar weekday number. */
export function hashToDayNumber(hash: string): number | null {
  const trimmed = hash.trim().toLowerCase();
  const slug = trimmed.startsWith("#") ? trimmed.slice(1) : trimmed;
  if (!slug) {
    return null;
  }
  return pathSlugToDayNumber(slug);
}

/**
 * Appends `#monday` when exactly one day is selected.
 * Strips any existing hash and any day path suffix on the last segment first.
 */
export function appendDayHash(path: string, days: number[]): string {
  const hashIndex = path.indexOf("#");
  const pathWithoutHash = hashIndex >= 0 ? path.slice(0, hashIndex) : path;

  // Venue pages use hash for day; strip any accidental path-day suffix.
  const queryIndex = pathWithoutHash.indexOf("?");
  const pathOnly =
    queryIndex >= 0 ? pathWithoutHash.slice(0, queryIndex) : pathWithoutHash;
  const query =
    queryIndex >= 0 ? pathWithoutHash.slice(queryIndex) : "";

  let cleanedPath = pathOnly;
  if (pathOnly !== "/" && pathOnly !== "") {
    const segments = pathOnly.split("/");
    const lastIndex = segments.length - 1;
    const last = segments[lastIndex] ?? "";
    if (last) {
      segments[lastIndex] = stripDaySuffix(last).base;
      cleanedPath = segments.join("/");
    }
  }

  const base = `${cleanedPath}${query}`;
  if (days.length !== 1) {
    return base;
  }
  const hash = dayNumberToHash(days[0]!);
  return hash ? `${base}${hash}` : base;
}

/** Replace or clear the day hash on the current URL (client-only). */
export function replaceDayHash(day: number | null): void {
  if (typeof window === "undefined") {
    return;
  }
  const { pathname, search } = window.location;
  const next =
    day === null
      ? `${pathname}${search}`
      : (() => {
          const hash = dayNumberToHash(day);
          return hash ? `${pathname}${search}${hash}` : `${pathname}${search}`;
        })();
  if (`${pathname}${search}${window.location.hash}` === next) {
    return;
  }
  window.history.replaceState(window.history.state, "", next);
}
