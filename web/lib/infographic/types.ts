export type InfographicFormat = "page" | "og" | "square" | "story";

export type InfographicSlotId =
  | "headline"
  | "coverageTriad"
  | "densest"
  | "perCapita"
  | "weekdayMix"
  | "dayHourHeat"
  | "topProducts"
  | "topFood"
  | "dealLeader";

export type CoverageTriadRingId =
  | "suburbsWithVenues"
  | "suburbsWithDeals"
  | "venuesWithDeals";

export type CoverageTriadRing = {
  id: CoverageTriadRingId;
  /** Coverage fill rate 0–100. */
  percent: number;
  numerator: number;
  denominator: number;
  /** Raw scale shown in the ring center. */
  scaleCount: number;
  scaleUnit: "suburbs" | "deals" | "venues";
};

export type RegionSuburbWinner = {
  name: string;
  postcode: string | null;
  value: number;
  dealCount: number;
};

export type RegionDayCount = {
  dayOfWeek: number;
  count: number;
};

export type RegionWeekdayShare = {
  dayOfWeek: number;
  count: number;
  percent: number;
};

export type RegionProductHit = {
  name: string;
  icon?: string;
  count: number;
  percent: number;
};

export type RegionDayHourCount = {
  dayOfWeek: number;
  hour: number;
  count: number;
};

export type RegionInfographicFacts = {
  regionId: number;
  regionName: string;
  dealCount: number;
  venueCount: number;
  venuesWithDeals: number;
  suburbCount: number;
  suburbsWithVenues: number;
  suburbsWithDeals: number;
  densestSuburb: RegionSuburbWinner | null;
  perCapitaSuburb: RegionSuburbWinner | null;
  dealLeaderSuburb: RegionSuburbWinner | null;
  busiestDay: RegionDayCount | null;
  dayCounts: RegionDayCount[];
  peakDayHour: RegionDayHourCount | null;
  dayHourCounts: RegionDayHourCount[];
  topProducts: RegionProductHit[];
  topFood: RegionProductHit[];
  /** Venues-with-deals %; also exposed on the coverage triad venue ring. */
  coveragePercent: number | null;
};

export type InfographicSlot =
  | {
      id: "headline";
      dealCount: number;
      venueCount: number;
    }
  | {
      id: "coverageTriad";
      rings: CoverageTriadRing[];
    }
  | {
      id: "densest";
      suburb: RegionSuburbWinner;
    }
  | {
      id: "perCapita";
      suburb: RegionSuburbWinner;
    }
  | {
      id: "weekdayMix";
      days: RegionWeekdayShare[];
      peakDayOfWeek: number;
    }
  | {
      id: "dayHourHeat";
      cells: RegionDayHourCount[];
      peakDayOfWeek: number;
      peakHour: number;
      peakCount: number;
      total: number;
    }
  | {
      id: "topProducts";
      products: RegionProductHit[];
    }
  | {
      id: "topFood";
      products: RegionProductHit[];
    }
  | {
      id: "dealLeader";
      suburb: RegionSuburbWinner;
    };

export type InfographicComposition = {
  format: InfographicFormat;
  regionName: string;
  slots: InfographicSlot[];
};

export const INFOGRAPHIC_IMAGE_SIZES: Record<
  Exclude<InfographicFormat, "page">,
  { width: number; height: number }
> = {
  og: { width: 1200, height: 630 },
  /** Portrait share sizes; keep in sync with layout height in render-image.tsx. */
  square: { width: 1080, height: 1280 },
  story: { width: 1080, height: 1600 },
};
