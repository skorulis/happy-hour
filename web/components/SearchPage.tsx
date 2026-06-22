"use client";

import { useEffect, useMemo, useState } from "react";
import { DealCard } from "@/components/DealCard";
import { DAY_OPTIONS } from "@/lib/search/schedule";
import type { DealSearchResult, VenueSearchResult } from "@/lib/search/queries";

export function SearchPage() {
  const [venueQuery, setVenueQuery] = useState("");
  const [venues, setVenues] = useState<VenueSearchResult[]>([]);
  const [selectedVenueId, setSelectedVenueId] = useState<number | "">("");
  const [day, setDay] = useState<number | "">("");
  const [textQuery, setTextQuery] = useState("");
  const [activeNow, setActiveNow] = useState(false);
  const [deals, setDeals] = useState<DealSearchResult[]>([]);
  const [loadingVenues, setLoadingVenues] = useState(false);
  const [loadingDeals, setLoadingDeals] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const controller = new AbortController();
    const timeout = setTimeout(async () => {
      setLoadingVenues(true);
      try {
        const params = new URLSearchParams();
        if (venueQuery.trim()) {
          params.set("q", venueQuery.trim());
        }
        params.set("limit", "20");

        const response = await fetch(`/api/venues?${params.toString()}`, {
          signal: controller.signal,
        });
        if (!response.ok) {
          throw new Error("Failed to load venues");
        }
        const data = (await response.json()) as { venues: VenueSearchResult[] };
        setVenues(data.venues);
      } catch (fetchError) {
        if ((fetchError as Error).name !== "AbortError") {
          setError("Could not load venues.");
        }
      } finally {
        setLoadingVenues(false);
      }
    }, 250);

    return () => {
      controller.abort();
      clearTimeout(timeout);
    };
  }, [venueQuery]);

  const selectedVenue = useMemo(
    () => venues.find((venue) => venue.id === selectedVenueId),
    [venues, selectedVenueId],
  );

  useEffect(() => {
    const controller = new AbortController();

    async function loadDeals() {
      setLoadingDeals(true);
      setError(null);

      try {
        const params = new URLSearchParams();
        if (selectedVenueId !== "") {
          params.set("venueId", String(selectedVenueId));
        }
        if (day !== "") {
          params.set("day", String(day));
        }
        if (textQuery.trim()) {
          params.set("q", textQuery.trim());
        }
        if (activeNow) {
          params.set("activeNow", "true");
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
  }, [selectedVenueId, day, textQuery, activeNow]);

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

      <section className="grid gap-4 rounded-2xl border border-zinc-200 bg-zinc-50 p-5 dark:border-zinc-800 dark:bg-zinc-900/40">
        <div className="grid gap-4 md:grid-cols-2">
          <label className="grid gap-2 text-sm font-medium text-zinc-700 dark:text-zinc-300">
            Venue
            <input
              type="search"
              value={venueQuery}
              onChange={(event) => setVenueQuery(event.target.value)}
              placeholder="Search venues..."
              className="rounded-lg border border-zinc-300 bg-white px-3 py-2 font-normal text-zinc-900 outline-none ring-amber-500 focus:ring-2 dark:border-zinc-700 dark:bg-zinc-950 dark:text-zinc-50"
            />
          </label>

          <label className="grid gap-2 text-sm font-medium text-zinc-700 dark:text-zinc-300">
            Select venue
            <select
              value={selectedVenueId}
              onChange={(event) =>
                setSelectedVenueId(
                  event.target.value ? Number(event.target.value) : "",
                )
              }
              className="rounded-lg border border-zinc-300 bg-white px-3 py-2 font-normal text-zinc-900 outline-none ring-amber-500 focus:ring-2 dark:border-zinc-700 dark:bg-zinc-950 dark:text-zinc-50"
            >
              <option value="">All venues</option>
              {venues.map((venue) => (
                <option key={venue.id} value={venue.id}>
                  {venue.name}
                </option>
              ))}
            </select>
          </label>
        </div>

        <div className="grid gap-4 md:grid-cols-2">
          <label className="grid gap-2 text-sm font-medium text-zinc-700 dark:text-zinc-300">
            Day
            <select
              value={day}
              onChange={(event) =>
                setDay(event.target.value ? Number(event.target.value) : "")
              }
              className="rounded-lg border border-zinc-300 bg-white px-3 py-2 font-normal text-zinc-900 outline-none ring-amber-500 focus:ring-2 dark:border-zinc-700 dark:bg-zinc-950 dark:text-zinc-50"
            >
              <option value="">Any day</option>
              {DAY_OPTIONS.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </label>

          <label className="grid gap-2 text-sm font-medium text-zinc-700 dark:text-zinc-300">
            Deal keywords
            <input
              type="search"
              value={textQuery}
              onChange={(event) => setTextQuery(event.target.value)}
              placeholder="steak, happy hour, pizza..."
              className="rounded-lg border border-zinc-300 bg-white px-3 py-2 font-normal text-zinc-900 outline-none ring-amber-500 focus:ring-2 dark:border-zinc-700 dark:bg-zinc-950 dark:text-zinc-50"
            />
          </label>
        </div>

        <label className="flex items-center gap-2 text-sm font-medium text-zinc-700 dark:text-zinc-300">
          <input
            type="checkbox"
            checked={activeNow}
            onChange={(event) => setActiveNow(event.target.checked)}
            className="h-4 w-4 rounded border-zinc-300 text-amber-600 focus:ring-amber-500"
          />
          Active right now
        </label>

        {selectedVenue ? (
          <p className="text-sm text-zinc-600 dark:text-zinc-400">
            Showing results for{" "}
            <span className="font-medium text-zinc-900 dark:text-zinc-100">
              {selectedVenue.name}
            </span>
          </p>
        ) : null}
      </section>

      <section className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-semibold text-zinc-900 dark:text-zinc-50">
            Results
          </h2>
          <p className="text-sm text-zinc-500 dark:text-zinc-400">
            {loadingDeals || loadingVenues ? "Loading..." : `${deals.length} deals`}
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
