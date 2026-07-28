export type InfographicFormat = "page" | "og" | "square" | "story";

export type InfographicSlotId =
  | "headline"
  | "densest"
  | "perCapita"
  | "weekdayMix"
  | "topProducts"
  | "coverage"
  | "dealLeader";

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

export type RegionInfographicFacts = {
  regionId: number;
  regionName: string;
  dealCount: number;
  venueCount: number;
  venuesWithDeals: number;
  densestSuburb: RegionSuburbWinner | null;
  perCapitaSuburb: RegionSuburbWinner | null;
  dealLeaderSuburb: RegionSuburbWinner | null;
  busiestDay: RegionDayCount | null;
  dayCounts: RegionDayCount[];
  topProducts: RegionProductHit[];
  coveragePercent: number | null;
};

export type InfographicSlot =
  | {
      id: "headline";
      dealCount: number;
      venueCount: number;
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
      id: "topProducts";
      products: RegionProductHit[];
    }
  | {
      id: "coverage";
      percent: number;
      venuesWithDeals: number;
      venueCount: number;
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
  /** Taller than 1:1 so weekday + drink charts + suburb tiles fit without clipping. */
  square: { width: 1080, height: 1620 },
  story: { width: 1080, height: 1920 },
};
