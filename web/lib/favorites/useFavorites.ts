"use client";

import { useCallback, useEffect, useState } from "react";
import {
  FAVORITES_STORAGE_KEY,
  readFavoriteDealIds,
  toggleFavoriteDealId,
  writeFavoriteDealIds,
} from "@/lib/favorites/storage";

export function useFavorites() {
  const [favoriteIds, setFavoriteIds] = useState<number[]>([]);

  useEffect(() => {
    setFavoriteIds(readFavoriteDealIds());

    function handleStorage(event: StorageEvent) {
      if (event.key === null || event.key === FAVORITES_STORAGE_KEY) {
        setFavoriteIds(readFavoriteDealIds());
      }
    }

    window.addEventListener("storage", handleStorage);
    return () => window.removeEventListener("storage", handleStorage);
  }, []);

  const isFavorite = useCallback(
    (dealId: number) => favoriteIds.includes(dealId),
    [favoriteIds],
  );

  const toggleFavorite = useCallback((dealId: number) => {
    setFavoriteIds((current) => {
      const next = toggleFavoriteDealId(current, dealId);
      writeFavoriteDealIds(next);
      return next;
    });
  }, []);

  return { isFavorite, toggleFavorite };
}
