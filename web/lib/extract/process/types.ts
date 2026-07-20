/**
 * Internal types for the deal-mapping pipeline.
 *
 * Ported from the Swift `DealScraper` models `DealDay`, `DealHours`, and
 * `LegacyDeal`. These are internal to `lib/extract/process` — the public wire
 * types live in `lib/extract/types.ts`.
 */

export type DealDay =
  | "monday"
  | "tuesday"
  | "wednesday"
  | "thursday"
  | "friday"
  | "saturday"
  | "sunday"
  | "everyDay";

/** Integer values represent minutes from midnight. 9AM = 540. */
export type DealHours =
  | { kind: "allDay" }
  | { kind: "from"; minutes: number }
  | { kind: "between"; start: number; end: number };

/** The TypeScript equivalent of Swift's `LegacyDeal`. */
export type MappedDeal = {
  title: string;
  details: string[];
  conditions: string[];
  days: DealDay[];
  times: DealHours[];
};

/** Stable key used for equality/deduplication of `DealHours` values. */
export function hoursKey(h: DealHours): string {
  switch (h.kind) {
    case "allDay":
      return "allDay";
    case "from":
      return `from:${h.minutes}`;
    case "between":
      return `between:${h.start}:${h.end}`;
  }
}

export function hoursEqual(a: DealHours, b: DealHours): boolean {
  return hoursKey(a) === hoursKey(b);
}

/** Deduplicates `DealHours`, preserving first-seen order. */
export function uniqueHours(hours: DealHours[]): DealHours[] {
  const seen = new Set<string>();
  const result: DealHours[] = [];
  for (const h of hours) {
    const key = hoursKey(h);
    if (seen.has(key)) continue;
    seen.add(key);
    result.push(h);
  }
  return result;
}
