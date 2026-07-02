"use client";

import { useSyncExternalStore } from "react";
import {
  FAVORITES_STORAGE_KEY,
  readFavoriteDealIds,
  toggleFavoriteDealId,
  writeFavoriteDealIds,
} from "@/lib/favorites/storage";

const EMPTY_FAVORITE_IDS: number[] = [];

let favoriteIds: number[] = EMPTY_FAVORITE_IDS;
let initialized = false;
const listeners = new Set<() => void>();

function emitChange() {
  for (const listener of listeners) {
    listener();
  }
}

function setFavoriteIds(next: number[]) {
  favoriteIds = next;
  emitChange();
}

function subscribe(listener: () => void) {
  if (!initialized) {
    initialized = true;
    favoriteIds = readFavoriteDealIds();
  }

  listeners.add(listener);

  function handleStorage(event: StorageEvent) {
    if (event.key === null || event.key === FAVORITES_STORAGE_KEY) {
      setFavoriteIds(readFavoriteDealIds());
    }
  }

  window.addEventListener("storage", handleStorage);

  return () => {
    listeners.delete(listener);
    window.removeEventListener("storage", handleStorage);
  };
}

function getSnapshot() {
  return favoriteIds;
}

function getServerSnapshot() {
  return EMPTY_FAVORITE_IDS;
}

function isFavorite(dealId: number) {
  return favoriteIds.includes(dealId);
}

function toggleFavorite(dealId: number) {
  const next = toggleFavoriteDealId(favoriteIds, dealId);
  writeFavoriteDealIds(next);
  setFavoriteIds(next);
}

export function useFavorites() {
  const currentFavoriteIds = useSyncExternalStore(
    subscribe,
    getSnapshot,
    getServerSnapshot,
  );

  return { favoriteIds: currentFavoriteIds, isFavorite, toggleFavorite };
}
