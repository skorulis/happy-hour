"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { groupDealsByVenue, VenueSearchCard } from "@/components/VenueSearchCard";
import { SearchBar, type SearchFilters } from "@/components/search/SearchBar";
import type { TimeRange } from "@/components/search/DayPicker";
import type { DealSearchResult } from "@/lib/search/queries";
import {
  filtersToSearchParams,
  searchParamsToFilters,
} from "@/lib/search/url";

export function SearchPage() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const isUpdatingUrl = useRef(false);

  const [filters, setFilters] = useState<SearchFilters>(() =>
    searchParamsToFilters(searchParams),
  );
  const [debouncedQuery, setDebouncedQuery] = useState(
    () => (searchParams.get("q") ?? "").trim(),
  );
  const [deals, setDeals] = useState<DealSearchResult[]>([]);
  const [loadingDeals, setLoadingDeals] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fromUrl = searchParamsToFilters(searchParams);

    if (isUpdatingUrl.current) {
      isUpdatingUrl.current = false;
      setFilters((current) => ({
        ...fromUrl,
        query: current.query,
      }));
      return;
    }

    setFilters(fromUrl);
    setDebouncedQuery(fromUrl.query.trim());
  }, [searchParams]);

  useEffect(() => {
    const timeout = setTimeout(() => {
      setDebouncedQuery(filters.query.trim());
    }, 250);

    return () => clearTimeout(timeout);
  }, [filters.query]);

  useEffect(() => {
    const nextParams = filtersToSearchParams(filters, debouncedQuery);
    const next = nextParams.toString();
    const current = searchParams.toString();

    if (next !== current) {
      isUpdatingUrl.current = true;
      router.replace(next ? `/?${next}` : "/", { scroll: false });
    }
  }, [
    debouncedQuery,
    filters.days,
    filters.timeRange,
    filters.where,
    router,
    searchParams,
  ]);

  useEffect(() => {
    const controller = new AbortController();

    async function loadDeals() {
      setLoadingDeals(true);
      setError(null);

      try {
        const params = filtersToSearchParams(filters, debouncedQuery);

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
  }, [filters.days, filters.where, filters.timeRange, debouncedQuery]);

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

  function handleQueryChange(query: string) {
    setFilters((current) => ({
      ...current,
      query,
    }));
  }

  const venueGroups = groupDealsByVenue(deals);

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-6 py-10">
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
        onQueryChange={handleQueryChange}
      />

      <section className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-semibold text-zinc-900 dark:text-zinc-50">
            Results
          </h2>
          <p className="text-sm text-zinc-500 dark:text-zinc-400">
            {loadingDeals
              ? "Loading..."
              : `${venueGroups.length} venues · ${deals.length} deals`}
          </p>
        </div>

        {error ? (
          <p className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/40 dark:text-red-300">
            {error}
          </p>
        ) : null}

        {!loadingDeals && deals.length === 0 ? (
          <p className="rounded-xl border border-dashed border-zinc-300 px-4 py-8 text-center text-sm text-zinc-500 dark:border-zinc-700 dark:text-zinc-400">
            No deals matched your filters. Try syncing data from DealScraper or
            broadening your search.
          </p>
        ) : (
          <div className="grid gap-4">
            {venueGroups.map((group) => (
              <VenueSearchCard key={group.venue.id} group={group} />
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
