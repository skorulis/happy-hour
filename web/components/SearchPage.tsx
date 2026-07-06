"use client";

import { VenueSearchCard } from "@/components/VenueSearchCard";
import { SearchBar } from "@/components/search/SearchBar";
import { useSearchFilters } from "@/lib/search/useSearchFilters";

export function SearchPage() {
  const {
    filters,
    venueGroups,
    nearbyVenueGroups,
    allVenueGroups,
    totalDeals,
    isEmpty,
    loadingDeals,
    error,
    resultsTitle,
    handleDaysApply,
    handleWhereChange,
    handleWhatChange,
  } = useSearchFilters();

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-6 py-10">
      <header>
        <h1 className="text-3xl font-bold text-zinc-900 dark:text-zinc-50">
          Find pub and bar deals
        </h1>
      </header>

      <SearchBar
        filters={filters}
        onDaysApply={handleDaysApply}
        onWhereChange={handleWhereChange}
        onWhatChange={handleWhatChange}
      />

      <section className="space-y-4">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <h2 className="text-xl font-semibold text-zinc-900 dark:text-zinc-50">
            {resultsTitle}
          </h2>
          <p className="text-sm text-zinc-500 dark:text-zinc-400">
            {loadingDeals
              ? "Loading..."
              : `${allVenueGroups.length} venues · ${totalDeals} deals`}
          </p>
        </div>

        {error ? (
          <p className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/40 dark:text-red-300">
            {error}
          </p>
        ) : null}

        {isEmpty ? (
          <p className="rounded-xl border border-dashed border-zinc-300 px-4 py-8 text-center text-sm text-zinc-500 dark:border-zinc-700 dark:text-zinc-400">
            No deals matched your filters. Try syncing data from DealScraper or
            broadening your search.
          </p>
        ) : (
          <div className="space-y-8">
            {venueGroups.length > 0 ? (
              <div className="grid gap-2">
                {venueGroups.map((group) => (
                  <VenueSearchCard
                    key={group.venue.id}
                    group={group}
                    searchDays={filters.days}
                  />
                ))}
              </div>
            ) : null}

            {nearbyVenueGroups.length > 0 ? (
              <div className="space-y-4">
                <h2 className="text-xl font-semibold text-zinc-900 dark:text-zinc-50">
                  Nearby
                </h2>
                <div className="grid gap-2">
                  {nearbyVenueGroups.map((group) => (
                    <VenueSearchCard
                      key={group.venue.id}
                      group={group}
                      searchDays={filters.days}
                    />
                  ))}
                </div>
              </div>
            ) : null}
          </div>
        )}
      </section>
    </div>
  );
}
