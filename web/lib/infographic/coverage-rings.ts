import type {
  CoverageTriadRing,
  RegionInfographicFacts,
} from "@/lib/infographic/types";

export const COVERAGE_RING_TRACK = "#1a2230";
export const COVERAGE_RING_FILL = "#f59e0b";
export const COVERAGE_RING_FILL_SOFT = "#fdba74";

export const COVERAGE_RING_VIEWBOX = 120;
export const COVERAGE_RING_CENTER = COVERAGE_RING_VIEWBOX / 2;
export const COVERAGE_RING_RADIUS = 48;
export const COVERAGE_RING_STROKE = 8;

export function clampCoveragePercent(percent: number): number {
  if (!Number.isFinite(percent)) return 0;
  return Math.min(100, Math.max(0, percent));
}

export function coveragePercentOf(numerator: number, denominator: number): number {
  if (denominator <= 0) return 0;
  return clampCoveragePercent((numerator / denominator) * 100);
}

/** Circumference of the progress ring for stroke-dasharray math. */
export function coverageRingCircumference(
  radius = COVERAGE_RING_RADIUS,
): number {
  return 2 * Math.PI * radius;
}

/**
 * strokeDasharray / strokeDashoffset for a progress ring that starts at 12 o'clock
 * when the SVG group is rotated -90deg around the center.
 */
export function coverageRingDash(
  percent: number,
  radius = COVERAGE_RING_RADIUS,
): { dasharray: string; dashoffset: number; circumference: number } {
  const circumference = coverageRingCircumference(radius);
  const filled =
    (clampCoveragePercent(percent) / 100) * circumference;
  return {
    dasharray: `${filled} ${circumference}`,
    dashoffset: 0,
    circumference,
  };
}

function venuesWithDealsRing(
  facts: Pick<RegionInfographicFacts, "venueCount" | "venuesWithDeals">,
): CoverageTriadRing {
  return {
    id: "venuesWithDeals",
    percent: coveragePercentOf(facts.venuesWithDeals, facts.venueCount),
    numerator: facts.venuesWithDeals,
    denominator: Math.max(facts.venueCount, 0),
    scaleCount: facts.venuesWithDeals,
    scaleUnit: "venues",
  };
}

export function buildCoverageTriadRings(
  facts: Pick<
    RegionInfographicFacts,
    | "suburbCount"
    | "suburbsWithVenues"
    | "suburbsWithDeals"
    | "venueCount"
    | "venuesWithDeals"
  >,
): CoverageTriadRing[] | null {
  if (facts.suburbCount <= 0) {
    return null;
  }

  return [
    {
      id: "suburbsWithVenues",
      percent: coveragePercentOf(
        facts.suburbsWithVenues,
        facts.suburbCount,
      ),
      numerator: facts.suburbsWithVenues,
      denominator: facts.suburbCount,
      scaleCount: facts.suburbsWithVenues,
      scaleUnit: "suburbs",
    },
    {
      id: "suburbsWithDeals",
      percent: coveragePercentOf(facts.suburbsWithDeals, facts.suburbCount),
      numerator: facts.suburbsWithDeals,
      denominator: facts.suburbCount,
      scaleCount: facts.suburbsWithDeals,
      scaleUnit: "suburbs",
    },
    venuesWithDealsRing(facts),
  ];
}

/** Suburb posters: single venues-with-deals ring until more metrics land. */
export function buildSuburbCoverageRings(
  facts: Pick<RegionInfographicFacts, "venueCount" | "venuesWithDeals">,
): CoverageTriadRing[] | null {
  if (facts.venueCount <= 0) {
    return null;
  }
  return [venuesWithDealsRing(facts)];
}

export function coverageRingEyebrow(ring: CoverageTriadRing): string {
  switch (ring.id) {
    case "suburbsWithVenues":
      return "Suburbs with venues";
    case "suburbsWithDeals":
      return "Suburbs with deals";
    case "venuesWithDeals":
      return "Venues with deals";
  }
}

export function coverageRingScaleUnitLabel(
  unit: CoverageTriadRing["scaleUnit"],
  count: number,
): string {
  if (unit === "suburbs") return count === 1 ? "suburb" : "suburbs";
  return count === 1 ? "venue" : "venues";
}

export function coverageRingSupporting(ring: CoverageTriadRing): string {
  const of = `${ring.numerator.toLocaleString("en-AU")} of ${ring.denominator.toLocaleString("en-AU")}`;
  switch (ring.id) {
    case "suburbsWithVenues":
      return `${of} suburbs have a venue`;
    case "suburbsWithDeals":
      return `${of} suburbs have a deal`;
    case "venuesWithDeals":
      return `${of} venues have a deal`;
  }
}

export function coverageTriadAriaLabel(rings: CoverageTriadRing[]): string {
  return rings
    .map((ring) => {
      const pct = Math.round(clampCoveragePercent(ring.percent));
      return `${coverageRingEyebrow(ring)}: ${pct}%; ${ring.scaleCount.toLocaleString("en-AU")} ${coverageRingScaleUnitLabel(ring.scaleUnit, ring.scaleCount)}`;
    })
    .join(". ");
}
