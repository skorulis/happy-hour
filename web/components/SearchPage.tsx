"use client";

import { PopularSuburbs } from "@/components/PopularSuburbs";
import { VenueSearchCard } from "@/components/VenueSearchCard";
import { SearchBar } from "@/components/search/SearchBar";
import type { WhereFilter } from "@/components/search/SuburbSelect";
import type { PopularSuburb } from "@/lib/search/queries";
import { filtersToBrowserSearchParams } from "@/lib/search/url";
import { useSearchFilters } from "@/lib/search/useSearchFilters";

type SearchPageProps = {
  initialWhere?: WhereFilter;
  popularSuburbs?: PopularSuburb[];
};

export function SearchPage({ initialWhere, popularSuburbs }: SearchPageProps) {
  const {
    filters,
    venueGroups,
    nearbyVenueGroups,
    allVenueGroups,
    totalDeals,
    isEmpty,
    loadingDeals,
    locating,
    error,
    resultsTitle,
    handleDaysApply,
    handleWhereChange,
    handleWhatChange,
  } = useSearchFilters({ initialWhere });

  const showPopularSuburbs =
    filters.where.kind === "anywhere" && popularSuburbs !== undefined;
  const popularSearch = filtersToBrowserSearchParams(
    filters,
    filters.what,
  ).toString();

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-6 py-10">
      <header>
        <h1 className="text-3xl font-bold text-foreground">
          Find pub and bar deals
        </h1>
      </header>

      <SearchBar
        filters={filters}
        onDaysApply={handleDaysApply}
        onWhereChange={handleWhereChange}
        onWhatChange={handleWhatChange}
      />

      {showPopularSuburbs ? (
        <section>
          <PopularSuburbs suburbs={popularSuburbs} search={popularSearch} />
        </section>
      ) : (
        <section className="space-y-4">
          <div className="space-y-1">
            <h2 className="text-xl font-semibold text-foreground">
              {resultsTitle}
            </h2>
            <p className="text-sm text-muted">
              {locating
                ? "Getting your location..."
                : loadingDeals
                  ? "Loading..."
                  : `${allVenueGroups.length} venues · ${totalDeals} deals`}
            </p>
          </div>

          {error ? (
            <p className="rounded-lg border border-border bg-danger-muted px-4 py-3 text-sm text-danger">
              {error}
            </p>
          ) : null}

          {locating || error ? null : isEmpty ? (
            <p className="rounded-xl border border-dashed border-border px-4 py-8 text-center text-sm text-muted">
              No deals matched your filters. Try syncing data from DealScraper or
              broadening your search.
            </p>
          ) : (
            <div className="space-y-8">
              {venueGroups.length > 0 ? (
                <div className="grid gap-4">
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
                <div className="space-y-4 border-t border-border-subtle pt-8">
                  <h2 className="text-xl font-semibold text-foreground">
                    Nearby
                  </h2>
                  <div className="grid gap-4">
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
      )}
    </div>
  );
}
