"use client";

import { useEffect, useMemo, useState } from "react";
import { BackToSearchLink } from "@/components/BackToSearchLink";
import { WeeklyDealsSection } from "@/components/WeeklyDealsSection";
import { useFavorites } from "@/lib/favorites/useFavorites";
import type { DealSearchResult } from "@/lib/search/queries";

const favouritesHeading = (count: number) => `Favourites (${count})`;
const favouritesEmptyMessage = "You haven't favourited any deals yet.";

export function FavouritesPageContent() {
  const { favoriteIds, isFavorite, toggleFavorite } = useFavorites();
  const [fetchedDeals, setFetchedDeals] = useState<DealSearchResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const favoriteIdsKey = favoriteIds.join(",");

  useEffect(() => {
    if (favoriteIds.length === 0) {
      setFetchedDeals([]);
      setLoading(false);
      setError(null);
      return;
    }

    const controller = new AbortController();

    async function loadFavouriteDeals() {
      setLoading(true);
      setError(null);

      try {
        const response = await fetch(
          `/api/deals?ids=${encodeURIComponent(favoriteIdsKey)}`,
          { signal: controller.signal },
        );

        if (!response.ok) {
          throw new Error("Failed to load favourite deals");
        }

        const data = (await response.json()) as { deals: DealSearchResult[] };
        setFetchedDeals(data.deals);
      } catch (fetchError) {
        if (controller.signal.aborted) {
          return;
        }

        setFetchedDeals([]);
        setError("Could not load your favourite deals.");
        console.error(fetchError);
      } finally {
        if (!controller.signal.aborted) {
          setLoading(false);
        }
      }
    }

    void loadFavouriteDeals();

    return () => controller.abort();
  }, [favoriteIds.length, favoriteIdsKey]);

  const deals = useMemo(
    () => fetchedDeals.filter((deal) => isFavorite(deal.id)),
    [fetchedDeals, favoriteIds, isFavorite],
  );

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-6 py-10">
      <div>
        <BackToSearchLink />
      </div>

      <header className="space-y-2">
        <h1 className="text-3xl font-bold text-zinc-900 dark:text-zinc-50">
          Favourites
        </h1>
      </header>

      {loading ? (
        <p className="text-sm text-zinc-500 dark:text-zinc-400">
          Loading your favourite deals...
        </p>
      ) : null}

      {error ? (
        <p className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/30 dark:text-red-300">
          {error}
        </p>
      ) : null}

      {!loading && !error ? (
        <WeeklyDealsSection
          deals={deals}
          showVenue
          heading={favouritesHeading}
          emptyMessage={favouritesEmptyMessage}
          isFavorite={isFavorite}
          onToggleFavorite={toggleFavorite}
        />
      ) : null}
    </div>
  );
}
