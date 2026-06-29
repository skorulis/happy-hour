"use client";

import dynamic from "next/dynamic";
import { useEffect, useRef, useState } from "react";
import { usePathname, useSearchParams } from "next/navigation";
import { groupDealsByVenue, VenueSearchCard } from "@/components/VenueSearchCard";
import { SearchBar, type SearchFilters } from "@/components/search/SearchBar";
import { ViewToggle } from "@/components/search/ViewToggle";
import type { TimeRange } from "@/components/search/DayPicker";
import type { DealSearchResult } from "@/lib/search/queries";
import {
  filtersToApiSearchParams,
  filtersToSearchParams,
  parseViewMode,
  searchParamsEqual,
  searchParamsToFilters,
  timeRangeKey,
  whatTokensEqual,
  whereFilterKey,
  type SearchViewMode,
} from "@/lib/search/url";

const SearchMapView = dynamic(
  () =>
    import("@/components/search/SearchMapView").then(
      (mod) => mod.SearchMapView,
    ),
  {
    ssr: false,
    loading: () => (
      <div className="flex min-h-[60vh] items-center justify-center rounded-xl border border-dashed border-zinc-300 text-sm text-zinc-500 dark:border-zinc-700 dark:text-zinc-400">
        Loading map...
      </div>
    ),
  },
);

function currentSearchString(): string {
  return window.location.search.startsWith("?")
    ? window.location.search.slice(1)
    : window.location.search;
}

export function SearchPage() {
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const syncedParamsRef = useRef(
    typeof window === "undefined" ? searchParams.toString() : currentSearchString(),
  );

  const [filters, setFilters] = useState<SearchFilters>(() =>
    searchParamsToFilters(searchParams),
  );
  const [viewMode, setViewMode] = useState<SearchViewMode>(() =>
    parseViewMode(searchParams),
  );
  const [debouncedWhat, setDebouncedWhat] = useState<string[]>(
    () => searchParamsToFilters(searchParams).what,
  );
  const [deals, setDeals] = useState<DealSearchResult[]>([]);
  const [loadingDeals, setLoadingDeals] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const whatKey = filters.what.join("\0");
  const debouncedWhatKey = debouncedWhat.join("\0");
  const daysKey = filters.days.join(",");
  const whereKey = whereFilterKey(filters.where);
  const scheduleKey = timeRangeKey(filters.timeRange);

  useEffect(() => {
    function syncFromBrowserUrl() {
      const current = currentSearchString();
      if (searchParamsEqual(current, syncedParamsRef.current)) {
        return;
      }

      syncedParamsRef.current = current;

      const params = new URLSearchParams(current);
      const fromUrl = searchParamsToFilters(params);
      setFilters(fromUrl);
      setDebouncedWhat(fromUrl.what);
      setViewMode(parseViewMode(params));
    }

    window.addEventListener("popstate", syncFromBrowserUrl);
    return () => window.removeEventListener("popstate", syncFromBrowserUrl);
  }, []);

  useEffect(() => {
    const timeout = setTimeout(() => {
      setDebouncedWhat((current) =>
        whatTokensEqual(filters.what, current) ? current : filters.what,
      );
    }, 250);

    return () => clearTimeout(timeout);
  }, [whatKey]);

  useEffect(() => {
    const next = filtersToSearchParams(
      filters,
      debouncedWhat,
      viewMode,
    ).toString();

    if (searchParamsEqual(next, syncedParamsRef.current)) {
      return;
    }

    syncedParamsRef.current = next;
    const href = next ? `${pathname}?${next}` : pathname;
    window.history.replaceState(window.history.state, "", href);
  }, [debouncedWhatKey, daysKey, scheduleKey, whereKey, viewMode, pathname]);

  useEffect(() => {
    const controller = new AbortController();

    async function loadDeals() {
      setLoadingDeals(true);
      setError(null);

      try {
        const params = filtersToApiSearchParams(filters, debouncedWhat);

        const response = await fetch(`/api/deals?${params.toString()}`, {
          signal: controller.signal,
        });
        if (!response.ok) {
          throw new Error("Failed to load deals");
        }
        const data = (await response.json()) as { deals: DealSearchResult[] };
        setDeals(data.deals);
      } catch (fetchError) {
        if ((fetchError as Error).name !== "AbortError") {
          setError("Could not load deals.");
        }
      } finally {
        setLoadingDeals(false);
      }
    }

    void loadDeals();

    return () => controller.abort();
  }, [daysKey, whereKey, scheduleKey, debouncedWhatKey]);

  function handleDaysApply(days: number[], timeRange: TimeRange) {
    setFilters((current) => ({
      ...current,
      days,
      timeRange,
    }));
  }

  function handleWhereChange(where: SearchFilters["where"]) {
    setFilters((current) => ({
      ...current,
      where,
    }));
  }

  function handleWhatChange(what: string[]) {
    setFilters((current) => ({
      ...current,
      what,
    }));
  }

  const venueGroups = groupDealsByVenue(deals);
  const userLocation =
    filters.where.kind === "nearMe"
      ? { lat: filters.where.lat, lng: filters.where.lng }
      : null;
  const isEmpty = !loadingDeals && deals.length === 0;
  const resultsTitle =
    filters.where.kind === "suburb"
      ? `Results in ${filters.where.suburb.name}`
      : "Results";

  return (
    <div
      className={`mx-auto flex w-full flex-1 flex-col gap-8 px-6 py-10 ${
        viewMode === "map" ? "max-w-6xl" : "max-w-4xl"
      }`}
    >
      <header className="space-y-2">
        <p className="text-sm font-medium uppercase tracking-wide text-amber-700 dark:text-amber-400">
          Happy Hour
        </p>
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
          <div className="flex flex-wrap items-center gap-3">
            <p className="text-sm text-zinc-500 dark:text-zinc-400">
              {loadingDeals
                ? "Loading..."
                : `${venueGroups.length} venues · ${deals.length} deals`}
            </p>
            <ViewToggle view={viewMode} onChange={setViewMode} />
          </div>
        </div>

        {error ? (
          <p className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/40 dark:text-red-300">
            {error}
          </p>
        ) : null}

        {viewMode === "list" ? (
          isEmpty ? (
            <p className="rounded-xl border border-dashed border-zinc-300 px-4 py-8 text-center text-sm text-zinc-500 dark:border-zinc-700 dark:text-zinc-400">
              No deals matched your filters. Try syncing data from DealScraper or
              broadening your search.
            </p>
          ) : (
            <div className="grid gap-2">
              {venueGroups.map((group) => (
                <VenueSearchCard key={group.venue.id} group={group} />
              ))}
            </div>
          )
        ) : (
          <SearchMapView
            venueGroups={venueGroups}
            userLocation={userLocation}
            isEmpty={isEmpty}
          />
        )}
      </section>
    </div>
  );
}
