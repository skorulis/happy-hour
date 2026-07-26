import Link from "next/link";
import { SearchDayPieChartClient } from "@/components/analytics/SearchDayPieChartClient";
import type { SearchDayCount } from "@/lib/analytics/queries";

type AnalyticsDashboardProps = {
  backHref: string;
  backLabel: string;
  heading: string;
  intro: string;
  searchDayDescription: string;
  searchesByDay: SearchDayCount[];
};

export function AnalyticsDashboard({
  backHref,
  backLabel,
  heading,
  intro,
  searchDayDescription,
  searchesByDay,
}: AnalyticsDashboardProps) {
  return (
    <div className="mx-auto flex w-full max-w-5xl flex-1 flex-col gap-10 px-4 py-10 md:px-6">
      <header className="space-y-3">
        <Link
          href={backHref}
          className="text-sm font-medium text-accent-soft transition-colors hover:text-foreground"
        >
          {backLabel}
        </Link>
        <div className="space-y-2">
          <h1 className="text-3xl font-bold text-foreground">{heading}</h1>
          <p className="max-w-2xl text-sm text-secondary">{intro}</p>
        </div>
      </header>

      <section aria-labelledby="search-day-heading" className="space-y-6">
        <div className="space-y-2">
          <h2
            id="search-day-heading"
            className="text-xl font-semibold text-foreground"
          >
            Search day of week
          </h2>
          <p className="text-sm text-secondary">{searchDayDescription}</p>
        </div>
        <SearchDayPieChartClient data={searchesByDay} />
      </section>
    </div>
  );
}
