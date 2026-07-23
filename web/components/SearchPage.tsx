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
  pageTitle?: string;
  listBasePath?: string;
  regionId?: number;
  allSuburbsHref?: string;
  includeNearbyLink?: boolean;
};

export function SearchPage({
  initialWhere,
  initialDays,
  initialWhat,
  initialDeals,
  initialNearbyDeals,
  popularSuburbs: initialPopularSuburbs,
  pageTitle,
  listBasePath,
  regionId,
  allSuburbsHref,
  includeNearbyLink = true,
}: SearchPageProps) {
  const {
    filters,
    venueGroups,
    nearbyVenueGroups,
    dealCount,
    nearbyDealCount,
    isEmpty,
    loadingDeals,
    loadingPopularSuburbs,
    popularSuburbs,
    locating,
    error,
    locationAccessError,
    resultsTitle,
    nearbyResultsTitle,
    handleDaysApply,
    handleWhereChange,
    handleWhatChange,
  } = useSearchFilters({
    initialWhere,
    initialDays,
    initialWhat,
    initialDeals,
    initialNearbyDeals,
    initialPopularSuburbs,
    listBasePath,
    regionId,
  });

  const showPopularSuburbs =
    (filters.where.kind === "anywhere" || regionId !== undefined) &&
    popularSuburbs !== undefined;
  const popularSearch = filtersToBrowserSearchParams(
    filters,
    filters.what,
  ).toString();
  const hasNearby = nearbyVenueGroups.length > 0;
  const resultsCountLabel = locating
    ? "Getting your location..."
    : loadingDeals
      ? "Loading..."
      : `${venueGroups.length} venues · ${dealCount} deals`;

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-4 py-10 md:px-6">
      <header>
        <h1 className="text-3xl font-bold text-foreground">
          {pageTitle ?? "Your evening starts here"}
        </h1>
      </header>

      <SearchBar
        filters={filters}
        onDaysApply={handleDaysApply}
        onWhereChange={handleWhereChange}
        onWhatChange={handleWhatChange}
        regionId={regionId}
      />

      {showPopularSuburbs ? (
        <section>
          {error ? (
            <p className="mb-4 rounded-lg border border-border bg-danger-muted px-4 py-3 text-sm text-danger">
              {error}
            </p>
          ) : null}
          <PopularSuburbs
            suburbs={popularSuburbs}
            search={popularSearch}
            includeSpecialLinks
            includeNearbyLink={includeNearbyLink}
            allSuburbsHref={allSuburbsHref}
            description={
              loadingPopularSuburbs
                ? "Loading..."
                : "Pick a suburb to browse deals nearby."
            }
          />
        </section>
      ) : (
        <section className="space-y-4">
          <div className="space-y-1">
            <h2 className="text-xl font-semibold text-foreground">
              {resultsTitle}
            </h2>
            {locationAccessError ? null : (
              <p className="text-sm text-muted">{resultsCountLabel}</p>
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

              {hasNearby ? (
                <div className="space-y-4 border-t border-border-subtle pt-8">
                  <div className="space-y-1">
                    <h2 className="text-xl font-semibold text-foreground">
                      {nearbyResultsTitle}
                    </h2>
                    <p className="text-sm text-muted">
                      {nearbyVenueGroups.length} venues · {nearbyDealCount}{" "}
                      deals
                    </p>
                  </div>
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
