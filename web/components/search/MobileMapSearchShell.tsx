"use client";

import { Search } from "lucide-react";
import {
  SearchBar,
  type SearchBarSegment,
  type SearchFilters,
} from "@/components/search/SearchBar";
import type { TimeRange } from "@/components/search/DayPicker";

const MAP_SEGMENTS: SearchBarSegment[] = ["when", "what"];

type MobileMapSearchShellProps = {
  filtersExpanded: boolean;
  onExpand: () => void;
  filters: SearchFilters;
  onDaysApply: (days: number[], timeRange: TimeRange) => void;
  onWhatChange: (what: string[]) => void;
};

export function MobileMapSearchShell({
  filtersExpanded,
  onExpand,
  filters,
  onDaysApply,
  onWhatChange,
}: MobileMapSearchShellProps) {
  return (
    <div
      className={`absolute top-4 right-4 z-10 overflow-hidden border border-border bg-surface-elevated shadow-md transition-[width,max-height,border-radius] duration-300 ease-in-out motion-reduce:transition-none ${
        filtersExpanded
          ? "w-[calc(100vw-2rem)] max-w-2xl max-h-[min(80vh,480px)] rounded-2xl"
          : "h-11 w-11 max-h-11 rounded-[1.375rem] hover:border-accent hover:bg-accent-muted"
      }`}
    >
      <div
        aria-hidden={!filtersExpanded}
        className={`transition-opacity duration-150 ease-in-out motion-reduce:transition-none motion-reduce:delay-0 ${
          filtersExpanded
            ? "pointer-events-auto opacity-100 delay-100"
            : "pointer-events-none opacity-0 delay-0"
        }`}
      >
        <SearchBar
          embedded
          className="max-w-none"
          filters={filters}
          segments={MAP_SEGMENTS}
          onDaysApply={onDaysApply}
          onWhatChange={onWhatChange}
        />
      </div>

      <button
        type="button"
        aria-label="Search filters"
        aria-hidden={filtersExpanded}
        tabIndex={filtersExpanded ? -1 : 0}
        onClick={onExpand}
        className={`absolute inset-0 inline-flex items-center justify-center text-secondary transition-opacity duration-150 ease-in-out motion-reduce:transition-none motion-reduce:delay-0 hover:text-accent-soft ${
          filtersExpanded
            ? "pointer-events-none opacity-0 delay-0"
            : "pointer-events-auto opacity-100 delay-100"
        }`}
      >
        <Search aria-hidden className="h-5 w-5" strokeWidth={1.75} />
      </button>
    </div>
  );
}
