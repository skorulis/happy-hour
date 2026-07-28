export type InfographicFormat = "page" | "og" | "square" | "story";

export type InfographicSlotId =
  | "headline"
  | "densest"
  | "perCapita"
  | "weekdayMix"
  | "dayHourHeat"
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
  densestSuburb: RegionSuburbWinner | null;
  perCapitaSuburb: RegionSuburbWinner | null;
  dealLeaderSuburb: RegionSuburbWinner | null;
  busiestDay: RegionDayCount | null;
  dayCounts: RegionDayCount[];
  peakDayHour: RegionDayHourCount | null;
  dayHourCounts: RegionDayHourCount[];
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
  /** Tall enough for weekday + heat + drink charts + suburb tiles. */
  square: { width: 1080, height: 1900 },
  story: { width: 1080, height: 2180 },
};
