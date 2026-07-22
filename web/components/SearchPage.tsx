"use client";

import { MapPinCheckInside } from "lucide-react";
import { PopularSuburbs } from "@/components/PopularSuburbs";
import { VenueSearchCard } from "@/components/VenueSearchCard";
import { SearchBar } from "@/components/search/SearchBar";
import type { WhereFilter } from "@/components/search/SuburbSelect";
import type { DealSearchResult, PopularSuburb } from "@/lib/search/queries";
import { filtersToBrowserSearchParams } from "@/lib/search/url";
import { useSearchFilters } from "@/lib/search/useSearchFilters";

type SearchPageProps = {
  initialWhere?: WhereFilter;
  initialDays?: number[];
  initialWhat?: string[];
  initialDeals?: DealSearchResult[];
  initialNearbyDeals?: DealSearchResult[];
  popularSuburbs?: PopularSuburb[];
};

export function SearchPage({
  initialWhere,
  initialDays,
  initialWhat,
  initialDeals,
  initialNearbyDeals,
  popularSuburbs,
}: SearchPageProps) {
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
    locationAccessError,
    resultsTitle,
    handleDaysApply,
    handleWhereChange,
    handleWhatChange,
  } = useSearchFilters({
    initialWhere,
    initialDays,
    initialWhat,
    initialDeals,
    initialNearbyDeals,
  });

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
        Your evening starts here
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
          <PopularSuburbs
            suburbs={popularSuburbs}
            search={popularSearch}
            includeSpecialLinks
          />
        </section>
      ) : (
        <section className="space-y-4">
          <div className="space-y-1">
            <h2 className="text-xl font-semibold text-foreground">
              {resultsTitle}
            </h2>
            {locationAccessError ? null : (
              <p className="text-sm text-muted">
                {locating
                  ? "Getting your location..."
                  : loadingDeals
                    ? "Loading..."
                    : `${allVenueGroups.length} venues · ${totalDeals} deals`}
              </p>
            )}
          </div>

          {locationAccessError ? (
            <div className="flex flex-col items-center gap-4 px-4 py-12 text-center">
              <MapPinCheckInside
                aria-hidden
                className="size-12 text-muted"
                strokeWidth={1.5}
              />
              <div className="space-y-1">
                <p className="text-base font-medium text-foreground">
                  This page needs your location to find nearby deals
                </p>
                <p className="text-sm text-muted">
                  Please enable location access in your browser
                </p>
              </div>
              <button
                type="button"
                className="rounded-lg bg-accent px-4 py-2 text-sm font-medium text-accent-fg transition-colors hover:bg-accent-hover"
                onClick={() => window.location.reload()}
              >
                Reload
              </button>
            </div>
          ) : error ? (
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
