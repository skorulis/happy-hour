"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import type { SearchFilters } from "@/components/search/SearchBar";
import type { TimeRange } from "@/components/search/DayPicker";
import type { WhereFilter } from "@/components/search/SuburbSelect";
import type { DealSearchResult, SuburbSearchResult } from "@/lib/search/queries";
import { boundsKey, type MapBounds } from "@/lib/search/bounds";
import {
  filtersToApiSearchParams,
  filtersToBrowserPath,
  filtersToBrowserSearchParams,
  filtersToMapApiSearchParams,
  parseWherePath,
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

function currentPathname(): string {
  return window.location.pathname;
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

function isNearMeReady(where: WhereFilter): boolean {
  return (
    where.kind === "nearMe" &&
    where.lat !== undefined &&
    where.lng !== undefined
  );
}

function isNearMePending(where: WhereFilter): boolean {
  return where.kind === "nearMe" && !isNearMeReady(where);
}

async function fetchSuburbBySlug(
  slug: string,
  signal?: AbortSignal,
): Promise<SuburbSearchResult | null> {
  const params = new URLSearchParams({ slug });
  const response = await fetch(`/api/suburbs/where?${params.toString()}`, {
    signal,
  });
  if (response.status === 404) {
    return null;
  }
  if (!response.ok) {
    throw new Error("Failed to load suburb");
  }
  const data = (await response.json()) as { suburb: SuburbSearchResult };
  return data.suburb;
}

export function useSearchFilters(options?: {
  mapViewport?: boolean;
  initialWhere?: WhereFilter;
}) {
  const mapViewport = options?.mapViewport ?? false;
  const initialWhere = options?.initialWhere ?? { kind: "anywhere" as const };
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const router = useRouter();
  const syncedParamsRef = useRef(
    typeof window === "undefined"
      ? searchParams.toString()
      : currentSearchString(),
  );
  const syncedPathRef = useRef(
    typeof window === "undefined" ? pathname : currentPathname(),
  );

  const [filters, setFilters] = useState<SearchFilters>(() =>
    searchParamsToInitialFilters(searchParams, initialWhere),
  );
  const [debouncedWhat, setDebouncedWhat] = useState<string[]>(
    () => searchParamsToInitialFilters(searchParams, initialWhere).what,
  );
  const [deals, setDeals] = useState<DealSearchResult[]>([]);
  const [nearbyDeals, setNearbyDeals] = useState<DealSearchResult[]>([]);
  const [loadingDeals, setLoadingDeals] = useState(false);
  const [locating, setLocating] = useState(() => isNearMePending(initialWhere));
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
      const path = currentPathname();
      const current = currentSearchString();
      if (
        path === syncedPathRef.current &&
        searchParamsEqual(current, syncedParamsRef.current)
      ) {
        return;
      }

      syncedPathRef.current = path;
      syncedParamsRef.current = current;

      const params = new URLSearchParams(current);
      const parsed = parseWherePath(path);

      if (parsed.kind === "nearby") {
        setFilters((currentFilters) => {
          const existingNearMe =
            currentFilters.where.kind === "nearMe"
              ? currentFilters.where
              : { kind: "nearMe" as const };
          return searchParamsToInitialFilters(params, existingNearMe);
        });
        setDebouncedWhat(searchParamsToInitialFilters(params).what);
        return;
      }

      if (parsed.kind === "suburb") {
        const slug = parsed.slug;
        void (async () => {
          try {
            const suburb = await fetchSuburbBySlug(slug);
            if (!suburb) {
              return;
            }
            if (currentPathname() !== path) {
              return;
            }
            const where: WhereFilter = {
              kind: "suburb",
              id: suburb.id,
              suburb,
            };
            const fromUrl = searchParamsToInitialFilters(params, where);
            setFilters(fromUrl);
            setDebouncedWhat(fromUrl.what);
          } catch {
            // Keep current filters if lookup fails during history navigation.
          }
        })();
        return;
      }

      const fromUrl = searchParamsToInitialFilters(params, {
        kind: "anywhere",
      });
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
    if (!isNearMePending(filters.where)) {
      setLocating(false);
      return;
    }

    if (!navigator.geolocation) {
      setLocating(false);
      setError("Location is not supported by your browser.");
      return;
    }

    let cancelled = false;
    setLocating(true);
    setError(null);

    navigator.geolocation.getCurrentPosition(
      (position) => {
        if (cancelled) {
          return;
        }
        setLocating(false);
        setFilters((current) => {
          if (current.where.kind !== "nearMe") {
            return current;
          }
          return {
            ...current,
            where: {
              kind: "nearMe",
              lat: position.coords.latitude,
              lng: position.coords.longitude,
            },
          };
        });
      },
      (geoError) => {
        if (cancelled) {
          return;
        }
        setLocating(false);
        setError(
          geoError.code === geoError.PERMISSION_DENIED
            ? "Location permission denied."
            : "Could not get your location.",
        );
      },
      { enableHighAccuracy: false, timeout: 10000 },
    );

    return () => {
      cancelled = true;
    };
  }, [whereKey]);

  useEffect(() => {
    const nextPath = filtersToBrowserPath(filters, pathname);
    const next = filtersToBrowserSearchParams(filters, debouncedWhat).toString();

    if (
      nextPath === syncedPathRef.current &&
      searchParamsEqual(next, syncedParamsRef.current)
    ) {
      return;
    }

    const pathChanged = nextPath !== syncedPathRef.current;
    syncedPathRef.current = nextPath;
    syncedParamsRef.current = next;
    const href = next ? `${nextPath}?${next}` : nextPath;

    if (pathChanged) {
      router.replace(href);
    } else {
      window.history.replaceState(window.history.state, "", href);
    }
  }, [
    debouncedWhatKey,
    daysKey,
    scheduleKey,
    whereKey,
    pathname,
    filters,
    router,
  ]);

  useEffect(() => {
    if (mapViewport && !viewportBounds) {
      return;
    }

    if (!mapViewport && isNearMePending(filters.where)) {
      return;
    }

    const controller = new AbortController();
    const filterChanged = filterKeyRef.current !== filterKey;
    filterKeyRef.current = filterKey;

    async function loadDeals() {
      setLoadingDeals(true);
      if (!isNearMePending(filters.where)) {
        setError(null);
      }

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
    filters.where.kind === "nearMe" &&
    filters.where.lat !== undefined &&
    filters.where.lng !== undefined
      ? { lat: filters.where.lat, lng: filters.where.lng }
      : null;
  const isEmpty = !loadingDeals && !locating && totalDeals === 0;
  const resultsTitle =
    filters.where.kind === "suburb"
      ? `Deals in ${filters.where.suburb.name}`
      : filters.where.kind === "nearMe"
        ? "Deals near you"
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
    locating,
    error,
    resultsTitle,
    handleDaysApply,
    handleWhereChange,
    handleWhatChange,
    setViewportBounds,
  };
}
