"use client";

import { PopularSuburbs } from "@/components/PopularSuburbs";
import type { SuburbStatistics } from "@/lib/search/queries";
import { suburbStatisticsPath } from "@/lib/search/slugs";

type RegionStatisticsViewProps = {
  suburbs: SuburbStatistics[];
  regionName: string;
};

export function RegionStatisticsView({ suburbs }: RegionStatisticsViewProps) {
  return (
    <PopularSuburbs
      suburbs={suburbs}
      statsMode="counts"
      hideHeader
      hideStats
      includeSpecialLinks={false}
      suburbHref={(suburb) =>
        suburbStatisticsPath(suburb.name, suburb.postcode)
      }
    />
  );
}
