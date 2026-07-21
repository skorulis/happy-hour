"use client";

import dynamic from "next/dynamic";
import { MapErrorBoundary } from "@/components/MapErrorBoundary";
import { SearchBar } from "@/components/search/SearchBar";
import type { WhereFilter } from "@/components/search/SuburbSelect";
import { useSearchFilters } from "@/lib/search/useSearchFilters";

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

  return (
    <div className="relative flex min-h-0 flex-1 flex-col">
      <div className="pointer-events-none absolute inset-x-0 top-0 z-10 flex justify-center px-4 pt-4">
        <SearchBar
          className="pointer-events-auto max-w-2xl"
          filters={filters}
          segments={["when", "what"]}
          onDaysApply={handleDaysApply}
          onWhatChange={handleWhatChange}
        />
      </div>

      <MapErrorBoundary fallback={<MapCrashFallback />}>
        <SearchMapView
          venueGroups={allVenueGroups}
          userLocation={userLocation}
          searchDays={filters.days}
          fullScreen
          onViewportIdle={setViewportBounds}
          autoFitBounds={false}
          initialBounds={initialMapBounds}
        />
      </MapErrorBoundary>
    </div>
  );
}
