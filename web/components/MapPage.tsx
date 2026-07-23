"use client";

import dynamic from "next/dynamic";
import { useCallback, useEffect, useState } from "react";
import { MapErrorBoundary } from "@/components/MapErrorBoundary";
import { MobileMapSearchShell } from "@/components/search/MobileMapSearchShell";
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
  initialDays?: number[];
};

export function MapPage({ initialWhere, initialDays }: MapPageProps) {
  const {
    filters,
    allVenueGroups,
    userLocation,
    initialMapBounds,
    handleDaysApply,
    handleWhatChange,
    setViewportBounds,
  } = useSearchFilters({
    mapViewport: true,
    initialWhere,
    initialDays,
  });

  const isMobile = useIsMobile();
  const [filtersExpanded, setFiltersExpanded] = useState(true);

  const handleUserMapInteract = useCallback(() => {
    setFiltersExpanded(false);
  }, []);

  return (
    <div className="relative flex min-h-0 flex-1 flex-col">
      {isMobile ? (
        <MobileMapSearchShell
          filtersExpanded={filtersExpanded}
          onExpand={() => setFiltersExpanded(true)}
          filters={filters}
          onDaysApply={handleDaysApply}
          onWhatChange={handleWhatChange}
        />
      ) : (
        <div className="pointer-events-none absolute inset-x-0 top-0 z-10 flex justify-center px-4 pt-4">
          <SearchBar
            className="pointer-events-auto max-w-2xl"
            filters={filters}
            segments={["when", "what"]}
            onDaysApply={handleDaysApply}
            onWhatChange={handleWhatChange}
          />
        </div>
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
