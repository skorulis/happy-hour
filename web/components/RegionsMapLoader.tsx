"use client";

import dynamic from "next/dynamic";
import type { RegionMapItem } from "@/lib/regions/map-data";

const RegionsMap = dynamic(
  () => import("@/components/RegionsMap").then((mod) => mod.RegionsMap),
  {
    ssr: false,
    loading: () => (
      <div className="flex aspect-[4/3] w-full max-h-[28rem] items-center justify-center text-sm text-muted">
        Loading map...
      </div>
    ),
  },
);

type RegionsMapLoaderProps = {
  regions: RegionMapItem[];
};

export function RegionsMapLoader({ regions }: RegionsMapLoaderProps) {
  return <RegionsMap regions={regions} />;
}
