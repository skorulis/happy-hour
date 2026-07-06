"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { usePathname, useSearchParams } from "next/navigation";
import type { SearchFilters } from "@/components/search/SearchBar";
import type { TimeRange } from "@/components/search/DayPicker";
import type { DealSearchResult } from "@/lib/search/queries";
import { boundsKey, type MapBounds } from "@/lib/search/bounds";
import {
  filtersToApiSearchParams,
  filtersToMapApiSearchParams,
  filtersToSearchParams,
  searchParamsEqual,
  searchParamsToInitialFilters,
  timeRangeKey,
  whatTokensEqual,
  whereFilterKey,
} from "@/lib/search/url";
import { groupDealsByVenue } from "@/components/VenueSearchCard";

function currentSearchString(): string {
  return window.location.search.startsWith("?")
    ? window.location.search.slice(1)
    : window.location.search;
}

function mergeDeals(
  existing: DealSearchResult[],
  incoming: DealSearchResult[],
): DealSearchResult[] {
  if (incoming.length === 0) {
    return existing;
  }

  const seenDealIds = new Set(existing.map((deal) => deal.id));
  const merged = [...existing];

  for (const deal of incoming) {
    if (!seenDealIds.has(deal.id)) {
      seenDealIds.add(deal.id);
      merged.push(deal);
    }
  }

  return merged;
}

export function useSearchFilters(options?: { mapViewport?: boolean }) {
  const mapViewport = options?.mapViewport ?? false;
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const syncedParamsRef = useRef(
    typeof window === "undefined"
      ? searchParams.toString()
      : currentSearchString(),
  );

  const [filters, setFilters] = useState<SearchFilters>(() =>
    searchParamsToInitialFilters(searchParams),
  );
  const [debouncedWhat, setDebouncedWhat] = useState<string[]>(
    () => searchParamsToInitialFilters(searchParams).what,
  );
  const [deals, setDeals] = useState<DealSearchResult[]>([]);
  const [nearbyDeals, setNearbyDeals] = useState<DealSearchResult[]>([]);
  const [loadingDeals, setLoadingDeals] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [viewportBounds, setViewportBoundsState] = useState<MapBounds | null>(
    null,
  );

  const setViewportBounds = useCallback((bounds: MapBounds) => {
    setViewportBoundsState((current) =>
      current && boundsKey(current) === boundsKey(bounds) ? current : bounds,
    );
  }, []);

  const whatKey = filters.what.join("\0");
  const debouncedWhatKey = debouncedWhat.join("\0");
  const daysKey = filters.days.join(",");
  const whereKey = whereFilterKey(filters.where);
  const scheduleKey = timeRangeKey(filters.timeRange);
  const viewportBoundsKey = viewportBounds ? boundsKey(viewportBounds) : "";
  const locationKey = mapViewport ? viewportBoundsKey : whereKey;
  const filterKey = `${daysKey}|${scheduleKey}|${debouncedWhatKey}`;
  const filterKeyRef = useRef(filterKey);

  useEffect(() => {
    function syncFromBrowserUrl() {
      const current = currentSearchString();
      if (searchParamsEqual(current, syncedParamsRef.current)) {
        return;
      }

      syncedParamsRef.current = current;

      const params = new URLSearchParams(current);
      const fromUrl = searchParamsToInitialFilters(params);
      setFilters(fromUrl);
      setDebouncedWhat(fromUrl.what);
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
    const next = filtersToSearchParams(filters, debouncedWhat).toString();

    if (searchParamsEqual(next, syncedParamsRef.current)) {
      return;
    }

    syncedParamsRef.current = next;
    const href = next ? `${pathname}?${next}` : pathname;
    window.history.replaceState(window.history.state, "", href);
  }, [debouncedWhatKey, daysKey, scheduleKey, whereKey, pathname]);

  useEffect(() => {
    if (mapViewport && !viewportBounds) {
      return;
    }

    const controller = new AbortController();
    const filterChanged = filterKeyRef.current !== filterKey;
    filterKeyRef.current = filterKey;

    async function loadDeals() {
      setLoadingDeals(true);
      setError(null);

      try {
        const params = mapViewport
          ? filtersToMapApiSearchParams(filters, debouncedWhat, viewportBounds!)
          : filtersToApiSearchParams(filters, debouncedWhat);

        const response = await fetch(`/api/deals?${params.toString()}`, {
          signal: controller.signal,
        });
        if (!response.ok) {
          throw new Error("Failed to load deals");
        }
        const data = (await response.json()) as {
          deals: DealSearchResult[];
          nearbyDeals?: DealSearchResult[];
        };

        if (mapViewport && !filterChanged) {
          setDeals((current) => mergeDeals(current, data.deals));
        } else {
          setDeals(data.deals);
        }

        setNearbyDeals(mapViewport ? [] : (data.nearbyDeals ?? []));
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
  }, [mapViewport, daysKey, scheduleKey, debouncedWhatKey, locationKey]);

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
  const nearbyVenueGroups = groupDealsByVenue(nearbyDeals);
  const allVenueGroups = [...venueGroups, ...nearbyVenueGroups];
  const totalDeals = deals.length + nearbyDeals.length;
  const userLocation =
    filters.where.kind === "nearMe"
      ? { lat: filters.where.lat, lng: filters.where.lng }
      : null;
  const isEmpty = !loadingDeals && totalDeals === 0;
  const resultsTitle =
    filters.where.kind === "suburb"
      ? `Deals in ${filters.where.suburb.name}`
      : "Results";

  return {
    filters,
    venueGroups,
    nearbyVenueGroups,
    allVenueGroups,
    totalDeals,
    userLocation,
    isEmpty,
    loadingDeals,
    error,
    resultsTitle,
    handleDaysApply,
    handleWhereChange,
    handleWhatChange,
    setViewportBounds,
  };
}
