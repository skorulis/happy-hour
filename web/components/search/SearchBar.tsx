"use client";

import { DayPicker, type TimeRange } from "@/components/search/DayPicker";
import { SuburbSelect, type WhereFilter } from "@/components/search/SuburbSelect";
import { WhatSelect } from "@/components/search/WhatSelect";

export type SearchFilters = {
  days: number[];
  timeRange: TimeRange;
  where: WhereFilter;
  what: string[];
};

type SearchBarProps = {
  filters: SearchFilters;
  onDaysApply: (days: number[], timeRange: TimeRange) => void;
  onWhereChange: (where: WhereFilter) => void;
  onWhatChange: (what: string[]) => void;
};

export function SearchBar({
  filters,
  onDaysApply,
  onWhereChange,
  onWhatChange,
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
            where={filters.where}
            onChange={onWhereChange}
          />
        </div>

        <div className="flex min-w-0 flex-1 items-center gap-2">
          <span className="hidden text-xs font-semibold uppercase tracking-wide text-zinc-500 md:inline">
            What
          </span>
          <WhatSelect tokens={filters.what} onChange={onWhatChange} />
        </div>
      </div>
    </section>
  );
}
