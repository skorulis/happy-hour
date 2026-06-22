"use client";

import { DayPicker, type TimeRange } from "@/components/search/DayPicker";
import { SuburbSelect } from "@/components/search/SuburbSelect";
import type { SuburbSearchResult } from "@/lib/search/queries";

export type SearchFilters = {
  days: number[];
  timeRange: TimeRange;
  suburbId: number | "";
  query: string;
};

type SearchBarProps = {
  filters: SearchFilters;
  selectedSuburb: SuburbSearchResult | null;
  onDaysApply: (days: number[], timeRange: TimeRange) => void;
  onSuburbChange: (suburbId: number | "", suburb: SuburbSearchResult | null) => void;
  onQueryChange: (query: string) => void;
};

export function SearchBar({
  filters,
  selectedSuburb,
  onDaysApply,
  onSuburbChange,
  onQueryChange,
}: SearchBarProps) {
  return (
    <section className="rounded-2xl border border-zinc-200 bg-zinc-50 p-4 dark:border-zinc-800 dark:bg-zinc-900/40">
      <div className="flex flex-col gap-3 md:flex-row md:items-center">
        <div className="flex shrink-0 items-center gap-2">
          <span className="hidden text-xs font-semibold uppercase tracking-wide text-zinc-500 md:inline">
            When
          </span>
          <DayPicker
            days={filters.days}
            timeRange={filters.timeRange}
            onApply={onDaysApply}
          />
        </div>

        <div className="flex min-w-0 flex-1 items-center gap-2">
          <span className="hidden text-xs font-semibold uppercase tracking-wide text-zinc-500 md:inline">
            Where
          </span>
          <SuburbSelect
            suburbId={filters.suburbId}
            selectedSuburb={selectedSuburb}
            onChange={onSuburbChange}
          />
        </div>

        <div className="flex min-w-0 flex-1 items-center gap-2">
          <span className="hidden text-xs font-semibold uppercase tracking-wide text-zinc-500 md:inline">
            What
          </span>
          <input
            type="search"
            value={filters.query}
            onChange={(event) => onQueryChange(event.target.value)}
            placeholder="steak, happy hour, pizza..."
            className="w-full rounded-full border border-zinc-300 bg-white px-4 py-2 text-sm font-medium text-zinc-900 outline-none ring-amber-500 focus:border-amber-500 focus:ring-2 dark:border-zinc-600 dark:bg-zinc-950 dark:text-zinc-50"
          />
        </div>
      </div>
    </section>
  );
}
