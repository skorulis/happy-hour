"use client";

import dynamic from "next/dynamic";
import { useCallback, useEffect, useState } from "react";
import { Search } from "lucide-react";
import { MapErrorBoundary } from "@/components/MapErrorBoundary";
import { SearchBar } from "@/components/search/SearchBar";
import type { WhereFilter } from "@/components/search/SuburbSelect";
import { useSearchFilters } from "@/lib/search/useSearchFilters";

const MOBILE_MEDIA_QUERY = "(max-width: 767px)";

const SearchMapView = dynamic(
  () =>
    import("@/components/search/SearchMapView").then(
      (mod) => mod.SearchMapView,
    ),
  {
    ssr: false,
    loading: () => (
      <div className="absolute inset-0 flex items-center justify-center bg-background text-sm text-muted">
        Loading map...
      </div>
    ),
  },
);

function MapCrashFallback() {
  return (
    <div className="absolute inset-0 flex items-center justify-center bg-surface-muted p-6 text-center text-sm text-muted">
      Map unavailable — something went wrong loading Google Maps. Try
      reloading the page.
    </div>
  );
}

function useIsMobile() {
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    const media = window.matchMedia(MOBILE_MEDIA_QUERY);
    function update() {
      setIsMobile(media.matches);
    }
    update();
    media.addEventListener("change", update);
    return () => media.removeEventListener("change", update);
  }, []);

  return isMobile;
}

type MapPageProps = {
  initialWhere?: WhereFilter;
};

export function MapPage({ initialWhere }: MapPageProps) {
  const {
    filters,
    allVenueGroups,
    userLocation,
    initialMapBounds,
    handleDaysApply,
    handleWhatChange,
    setViewportBounds,
  } = useSearchFilters({ mapViewport: true, initialWhere });

  const isMobile = useIsMobile();
  const [filtersExpanded, setFiltersExpanded] = useState(true);

  const handleUserMapInteract = useCallback(() => {
    setFiltersExpanded(false);
  }, []);

  const showSearchBar = !isMobile || filtersExpanded;

  return (
    <div className="relative flex min-h-0 flex-1 flex-col">
      {showSearchBar ? (
        <div className="pointer-events-none absolute inset-x-0 top-0 z-10 flex justify-center px-4 pt-4">
          <SearchBar
            className="pointer-events-auto max-w-2xl"
            filters={filters}
            segments={["when", "what"]}
            onDaysApply={handleDaysApply}
            onWhatChange={handleWhatChange}
          />
        </div>
      ) : (
        <button
          type="button"
          aria-label="Search filters"
          onClick={() => setFiltersExpanded(true)}
          className="absolute top-4 right-4 z-10 inline-flex h-11 w-11 items-center justify-center rounded-full border border-border bg-surface-elevated text-secondary shadow-md transition-colors hover:border-accent hover:bg-accent-muted hover:text-accent-soft"
        >
          <Search aria-hidden className="h-5 w-5" strokeWidth={1.75} />
        </button>
      )}

      <MapErrorBoundary fallback={<MapCrashFallback />}>
        <SearchMapView
          venueGroups={allVenueGroups}
          userLocation={userLocation}
          searchDays={filters.days}
          fullScreen
          onViewportIdle={setViewportBounds}
          autoFitBounds={false}
          initialBounds={initialMapBounds}
          onUserMapInteract={handleUserMapInteract}
        />
      </MapErrorBoundary>
    </div>
  );
}
