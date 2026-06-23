"use client";

import { useEffect, useState } from "react";
import { DealCard } from "@/components/DealCard";
import { SearchBar, type SearchFilters } from "@/components/search/SearchBar";
import type { TimeRange } from "@/components/search/DayPicker";
import type { DealSearchResult } from "@/lib/search/queries";

export function SearchPage() {
  const [filters, setFilters] = useState<SearchFilters>({
    days: [],
    timeRange: null,
    where: { kind: "anywhere" },
    query: "",
  });
  const [debouncedQuery, setDebouncedQuery] = useState("");
  const [deals, setDeals] = useState<DealSearchResult[]>([]);
  const [loadingDeals, setLoadingDeals] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const timeout = setTimeout(() => {
      setDebouncedQuery(filters.query);
    }, 250);

    return () => clearTimeout(timeout);
  }, [filters.query]);

  useEffect(() => {
    const controller = new AbortController();

    async function loadDeals() {
      setLoadingDeals(true);
      setError(null);

      try {
        const params = new URLSearchParams();

        if (filters.days.length > 0) {
          params.set("days", filters.days.join(","));
        }
        if (filters.where.kind === "suburb") {
          params.set("suburbId", String(filters.where.id));
        } else if (filters.where.kind === "nearMe") {
          params.set("lat", String(filters.where.lat));
          params.set("lng", String(filters.where.lng));
        }
        if (filters.timeRange) {
          params.set("startMinute", String(filters.timeRange.startMinute));
          params.set("endMinute", String(filters.timeRange.endMinute));
        }
        if (debouncedQuery.trim()) {
          params.set("q", debouncedQuery.trim());
        }

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
            {loadingDeals ? "Loading..." : `${deals.length} deals`}
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
            {deals.map((deal) => (
              <DealCard key={deal.id} deal={deal} />
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
