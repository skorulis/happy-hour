"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import type { SearchFilters } from "@/components/search/SearchBar";
import type { TimeRange } from "@/components/search/DayPicker";
import type { WhereFilter } from "@/components/search/SuburbSelect";
import { track } from "@/lib/analytics/client";
import type { DealSearchResult, SuburbSearchResult } from "@/lib/search/queries";
import {
  boundsFromCenterRadiusKm,
  boundsKey,
  type MapBounds,
} from "@/lib/search/bounds";
import {
  markMapEntryCameraApplied,
  readPendingMapEntryCamera,
  readSeededMapBounds,
  rememberSeededMapBounds,
} from "@/lib/search/map-entry";
import {
  NEAR_ME_MAP_RADIUS_KM,
  VENUE_MAP_RADIUS_KM,
  nearbySuburbRadiusKm,
} from "@/lib/search/nearby-radius";
import { suburbWhereSlug } from "@/lib/search/slugs";
import { formatSuburbDealsTitle } from "@/lib/search/schedule";
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

function filtersFromSeed(
  where: WhereFilter,
  days?: number[],
  what?: string[],
): SearchFilters {
  return {
    days: days ?? [],
    timeRange: null,
    where,
    what: what ?? [],
  };
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

function isNearMeReady(
  where: WhereFilter,
): where is { kind: "nearMe"; lat: number; lng: number } {
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
  initialDays?: number[];
  initialWhat?: string[];
  initialDeals?: DealSearchResult[];
  initialNearbyDeals?: DealSearchResult[];
}) {
  const mapViewport = options?.mapViewport ?? false;
  const initialWhere = options?.initialWhere ?? { kind: "anywhere" as const };
  const initialDeals = options?.initialDeals ?? [];
  const initialNearbyDeals = options?.initialNearbyDeals ?? [];
  const seededFilters = filtersFromSeed(
    initialWhere,
    options?.initialDays,
    options?.initialWhat,
  );
  const pathname = usePathname();
  const router = useRouter();
  // Seed from filter state (not window) so the mount sync can detect home/map
  // deep links whose query string was not passed as server props.
  const syncedParamsRef = useRef(
    filtersToBrowserSearchParams(seededFilters, seededFilters.what).toString(),
  );
  const syncedPathRef = useRef(pathname);
  // First client fetch after SSR seed (all-days → today, or matching ?days=)
  // should not flash "Loading…" over already-rendered cards.
  const skipLoadingOnceRef = useRef(
    initialDeals.length > 0 || initialNearbyDeals.length > 0,
  );

  const [filters, setFilters] = useState<SearchFilters>(seededFilters);
  const [debouncedWhat, setDebouncedWhat] = useState<string[]>(
    () => seededFilters.what,
  );
  const [deals, setDeals] = useState<DealSearchResult[]>(initialDeals);
  const [nearbyDeals, setNearbyDeals] =
    useState<DealSearchResult[]>(initialNearbyDeals);
  const [loadingDeals, setLoadingDeals] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [viewportBounds, setViewportBoundsState] = useState<MapBounds | null>(
    () => (mapViewport ? readSeededMapBounds() : null),
  );
  const [initialMapBounds, setInitialMapBounds] = useState<MapBounds | null>(
    () => (mapViewport ? readSeededMapBounds() : null),
  );
  const nearbyCameraPendingRef = useRef(false);

  const setViewportBounds = useCallback((bounds: MapBounds) => {
    setViewportBoundsState((current) =>
      current && boundsKey(current) === boundsKey(bounds) ? current : bounds,
    );
  }, []);

  const applyInitialMapBounds = useCallback((bounds: MapBounds) => {
    rememberSeededMapBounds(bounds);
    setViewportBoundsState((current) =>
      current && boundsKey(current) === boundsKey(bounds) ? current : bounds,
    );
    setInitialMapBounds((current) =>
      current && boundsKey(current) === boundsKey(bounds) ? current : bounds,
    );
    markMapEntryCameraApplied();
  }, []);

  const whatKey = filters.what.join("\0");
  const debouncedWhatKey = debouncedWhat.join("\0");
  const daysKey = filters.days.join(",");
  const whereKey = whereFilterKey(filters.where);
  const nearMePending = isNearMePending(filters.where);
  const geolocationUnavailable =
    typeof navigator !== "undefined" && !navigator.geolocation;
  const locating =
    nearMePending && !geolocationUnavailable && error === null;
  const scheduleKey = timeRangeKey(filters.timeRange);
  const viewportBoundsKey = viewportBounds ? boundsKey(viewportBounds) : "";
  const locationKey = mapViewport ? viewportBoundsKey : whereKey;
  const filterKey = `${daysKey}|${scheduleKey}|${debouncedWhatKey}`;
  const filterKeyRef = useRef(filterKey);

  useEffect(() => {
    if (!mapViewport) {
      return;
    }

    const entry = readPendingMapEntryCamera();
    if (!entry) {
      return;
    }

    if (entry.source.kind === "nearby") {
      nearbyCameraPendingRef.current = true;
      // Seeding the where filter from the stored map entry must run after mount:
      // sessionStorage is unavailable during SSR, so doing this any earlier
      // would cause a hydration mismatch on the initial filter state.
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setFilters((current) => ({
        ...current,
        where: { kind: "nearMe" },
      }));
      setError(null);
      return;
    }

    if (entry.source.kind === "anywhere") {
      markMapEntryCameraApplied();
      return;
    }

    if (entry.source.kind === "venue") {
      const bounds = boundsFromCenterRadiusKm(
        entry.source.lat,
        entry.source.lng,
        VENUE_MAP_RADIUS_KM,
      );
      if (bounds) {
        // Seeds the map camera from the venue page entry written before navigation.
        applyInitialMapBounds(bounds);
      } else {
        markMapEntryCameraApplied();
      }
      return;
    }

    if (entry.source.kind !== "suburb") {
      return;
    }

    const slug = entry.source.slug;
    let cancelled = false;

    void (async () => {
      try {
        const suburb = await fetchSuburbBySlug(slug);
        if (cancelled || !suburb || suburb.lat == null || suburb.lng == null) {
          return;
        }

        const bounds = boundsFromCenterRadiusKm(
          suburb.lat,
          suburb.lng,
          nearbySuburbRadiusKm(suburb.sqkm),
        );
        if (!bounds || cancelled) {
          return;
        }

        applyInitialMapBounds(bounds);
        setFilters((current) => ({
          ...current,
          where: {
            kind: "suburb",
            id: suburb.id,
            suburb,
          },
        }));
      } catch {
        // Keep default map camera if suburb lookup fails.
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [mapViewport, applyInitialMapBounds]);

  useEffect(() => {
    if (!mapViewport || !nearbyCameraPendingRef.current) {
      return;
    }

    if (!isNearMeReady(filters.where)) {
      return;
    }

    const bounds = boundsFromCenterRadiusKm(
      filters.where.lat,
      filters.where.lng,
      NEAR_ME_MAP_RADIUS_KM,
    );
    nearbyCameraPendingRef.current = false;
    if (bounds) {
      // Seeds the map camera once geolocation asynchronously resolves the
      // near-me coordinates; this is a genuine reaction to an external event.
      // eslint-disable-next-line react-hooks/set-state-in-effect
      applyInitialMapBounds(bounds);
    }
  }, [mapViewport, whereKey, filters.where, applyInitialMapBounds]);

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

    // Align with the real URL after hydration (home/map deep links) without
    // useSearchParams, which would suspend the whole results tree.
    syncFromBrowserUrl();
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
  }, [whatKey, filters.what]);

  useEffect(() => {
    if (!nearMePending) {
      return;
    }

    if (geolocationUnavailable) {
      return;
    }

    let cancelled = false;

    navigator.geolocation.getCurrentPosition(
      (position) => {
        if (cancelled) {
          return;
        }
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
  }, [whereKey, nearMePending, geolocationUnavailable]);

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
    debouncedWhat,
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
      if (!mapViewport && filters.where.kind === "anywhere") {
        setDeals([]);
        setNearbyDeals([]);
        setLoadingDeals(false);
        return;
      }

      if (skipLoadingOnceRef.current) {
        // Keep seeded SSR cards visible during the first refine (all-days → today).
      } else {
        setLoadingDeals(true);
      }
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

        const nearby = mapViewport ? [] : (data.nearbyDeals ?? []);
        setNearbyDeals(nearby);
        skipLoadingOnceRef.current = false;

        if (filterChanged || !mapViewport) {
          const whereKind = filters.where.kind;
          track("search_performed", {
            view: mapViewport ? "map" : "list",
            where_kind: whereKind,
            suburb_slug:
              whereKind === "suburb"
                ? suburbWhereSlug(
                    filters.where.suburb.name,
                    filters.where.suburb.postcode,
                  )
                : null,
            days: filters.days.slice().sort((a, b) => a - b).join(","),
            time: timeRangeKey(filters.timeRange) || null,
            what: debouncedWhat.join(",") || null,
            result_count: data.deals.length + nearby.length,
          });
        }
      } catch (fetchError) {
        if ((fetchError as Error).name !== "AbortError") {
          setError("Could not load deals.");
          skipLoadingOnceRef.current = false;
        }
      } finally {
        setLoadingDeals(false);
      }
    }

    void loadDeals();

    return () => controller.abort();
  }, [
    mapViewport,
    daysKey,
    scheduleKey,
    debouncedWhatKey,
    debouncedWhat,
    filterKey,
    filters,
    locationKey,
    viewportBounds,
  ]);

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
    if (where.kind === "nearMe" && !isNearMeReady(where)) {
      setError(null);
    }
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
  const geolocationError =
    nearMePending && geolocationUnavailable
      ? "Location is not supported by your browser."
      : null;
  const displayError = error ?? geolocationError;
  const locationAccessError = nearMePending && displayError !== null;
  const resultsTitle =
    filters.where.kind === "suburb"
      ? formatSuburbDealsTitle(
          filters.where.suburb.name,
          filters.days,
          filters.what,
        )
      : filters.where.kind === "nearMe"
        ? "Specials near you"
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
    error: displayError,
    locationAccessError,
    resultsTitle,
    initialMapBounds,
    handleDaysApply,
    handleWhereChange,
    handleWhatChange,
    setViewportBounds,
  };
}
