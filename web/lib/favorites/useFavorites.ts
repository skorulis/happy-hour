"use client";

import { useEffect, useRef } from "react";
import { useSyncExternalStore } from "react";
import { useSession } from "@/lib/auth-client";
import { fetchFavorites, setFavorite } from "@/lib/favorites/api";
import {
  FAVORITES_STORAGE_KEY,
  readFavoriteDealIds,
  toggleFavoriteDealId,
  writeFavoriteDealIds,
} from "@/lib/favorites/storage";
import { unionFavoriteDealIds } from "@/lib/favorites/sync";

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

async function syncWithServer() {
  try {
    const serverIds = await fetchFavorites();
    const localIds = readFavoriteDealIds();
    const merged = unionFavoriteDealIds(localIds, serverIds);

    writeFavoriteDealIds(merged);
    setFavoriteIds(merged);

    const serverIdSet = new Set(serverIds);
    const localOnlyIds = localIds.filter((id) => !serverIdSet.has(id));

    for (const dealId of localOnlyIds) {
      try {
        await setFavorite(dealId, true);
      } catch {
        // Keep local as source of UI; ignore failed sync for v1.
      }
    }
  } catch {
    // Keep local favourites if the server sync fails.
  }
}

export function useFavorites() {
  const { data: session } = useSession();
  const syncedUserIdRef = useRef<string | null>(null);

  const currentFavoriteIds = useSyncExternalStore(
    subscribe,
    getSnapshot,
    getServerSnapshot,
  );

  useEffect(() => {
    const userId = session?.user.id ?? null;

    if (!userId) {
      if (syncedUserIdRef.current !== null) {
        syncedUserIdRef.current = null;
        writeFavoriteDealIds([]);
        setFavoriteIds(EMPTY_FAVORITE_IDS);
      }
      return;
    }

    if (syncedUserIdRef.current === userId) {
      return;
    }

    syncedUserIdRef.current = userId;
    void syncWithServer();
  }, [session?.user.id]);

  function toggleFavorite(dealId: number) {
    const next = toggleFavoriteDealId(favoriteIds, dealId);
    const favorited = next.includes(dealId);

    writeFavoriteDealIds(next);
    setFavoriteIds(next);

    if (session?.user.id) {
      void setFavorite(dealId, favorited).catch(() => {
        // Keep local as source of UI; ignore failed sync for v1.
      });
    }
  }

  return {
    favoriteIds: currentFavoriteIds,
    isFavorite,
    toggleFavorite,
  };
}
