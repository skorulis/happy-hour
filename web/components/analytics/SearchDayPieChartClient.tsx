"use client";

import dynamic from "next/dynamic";
import type { SearchDayCount } from "@/lib/analytics/queries";

const SearchDayPieChart = dynamic(
  () =>
    import("@/components/analytics/SearchDayPieChart").then(
      (mod) => mod.SearchDayPieChart,
    ),
  {
    ssr: false,
    loading: () => (
      <p className="py-12 text-center text-sm text-muted">Loading chart…</p>
    ),
  },
);

type SearchDayPieChartClientProps = {
  data: SearchDayCount[];
};

export function SearchDayPieChartClient({ data }: SearchDayPieChartClientProps) {
  return <SearchDayPieChart data={data} />;
}
