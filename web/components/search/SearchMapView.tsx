"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { resolveVenueMapIcon } from "@/lib/search/map-icon";
import {
  AdvancedMarker,
  APILoadingStatus,
  APIProvider,
  InfoWindow,
  Map,
  Pin,
  useAdvancedMarkerRef,
  useApiLoadingStatus,
  useMap,
} from "@vis.gl/react-google-maps";
import type { VenueGroupedDeals } from "@/components/VenueSearchCard";
import { VenueMapPopup } from "@/components/search/VenueMapPopup";
import { track } from "@/lib/analytics/client";
import { hasAnyDealActiveNow } from "@/lib/search/schedule";
import {
  boundsFromGoogleMap,
  boundsKey,
  type MapBounds,
} from "@/lib/search/bounds";
import {
  isRegisteredProductIcon,
  ProductMapIcon,
} from "@/lib/search/ProductMapIcon";

const DEFAULT_CENTER = { lat: -33.87, lng: 151.21 };
const DEFAULT_ZOOM = 11;
const VIEWPORT_IDLE_DEBOUNCE_MS = 300;

const googleMapsApiKey = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY;
const googleMapsMapId = process.env.NEXT_PUBLIC_GOOGLE_MAPS_MAP_ID;

type UserLocation = {
  lat: number;
  lng: number;
};

type SearchMapViewProps = {
  venueGroups: VenueGroupedDeals[];
  userLocation: UserLocation | null;
  isEmpty: boolean;
  searchDays?: number[];
  fullScreen?: boolean;
  onViewportIdle?: (bounds: MapBounds) => void;
  autoFitBounds?: boolean;
  initialBounds?: MapBounds | null;
};

type SelectedMarker = number | "user" | null;

function FitBounds({
  venueGroups,
  userLocation,
}: {
  venueGroups: VenueGroupedDeals[];
  userLocation: UserLocation | null;
}) {
  const map = useMap();

  useEffect(() => {
    if (!map) {
      return;
    }

    const points: google.maps.LatLngLiteral[] = venueGroups.map((group) => ({
      lat: group.venue.lat,
      lng: group.venue.lng,
    }));

    if (userLocation) {
      points.push({ lat: userLocation.lat, lng: userLocation.lng });
    }

    if (points.length === 0) {
      map.setCenter(DEFAULT_CENTER);
      map.setZoom(DEFAULT_ZOOM);
      return;
    }

    if (points.length === 1) {
      map.setCenter(points[0]);
      map.setZoom(14);
      return;
    }

    const bounds = new google.maps.LatLngBounds();
    for (const point of points) {
      bounds.extend(point);
    }
    map.fitBounds(bounds, { top: 48, right: 48, bottom: 48, left: 48 });
  }, [map, venueGroups, userLocation]);

  return null;
}

function InitialBounds({ bounds }: { bounds: MapBounds }) {
  const map = useMap();
  const appliedKeyRef = useRef<string | null>(null);

  useEffect(() => {
    if (!map) {
      return;
    }

    const key = boundsKey(bounds);
    if (appliedKeyRef.current === key) {
      return;
    }

    appliedKeyRef.current = key;
    map.fitBounds(
      {
        north: bounds.north,
        south: bounds.south,
        east: bounds.east,
        west: bounds.west,
      },
      { top: 48, right: 48, bottom: 48, left: 48 },
    );
  }, [map, bounds]);

  return null;
}

function ViewportIdleReporter({
  onViewportIdle,
}: {
  onViewportIdle: (bounds: MapBounds) => void;
}) {
  const map = useMap();
  const onViewportIdleRef = useRef(onViewportIdle);
  const lastBoundsKeyRef = useRef<string | null>(null);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    onViewportIdleRef.current = onViewportIdle;
  }, [onViewportIdle]);

  useEffect(() => {
    if (!map) {
      return;
    }

    function reportBounds() {
      const bounds = boundsFromGoogleMap(map!);
      if (!bounds) {
        return;
      }

      const key = boundsKey(bounds);
      if (key === lastBoundsKeyRef.current) {
        return;
      }

      lastBoundsKeyRef.current = key;
      onViewportIdleRef.current(bounds);
    }

    const listener = map.addListener("idle", () => {
      if (debounceRef.current) {
        clearTimeout(debounceRef.current);
      }

      debounceRef.current = setTimeout(reportBounds, VIEWPORT_IDLE_DEBOUNCE_MS);
    });

    return () => {
      listener.remove();
      if (debounceRef.current) {
        clearTimeout(debounceRef.current);
      }
    };
  }, [map]);

  return null;
}

function useCurrentMinute(): Date {
  const [now, setNow] = useState(() => new Date());

  useEffect(() => {
    const interval = setInterval(() => setNow(new Date()), 60_000);
    return () => clearInterval(interval);
  }, []);

  return now;
}

function VenueMarker({
  group,
  searchDays,
  now,
  isSelected,
  onSelect,
  onClose,
}: {
  group: VenueGroupedDeals;
  searchDays: number[];
  now: Date;
  isSelected: boolean;
  onSelect: (venueId: number) => void;
  onClose: () => void;
}) {
  const [markerRef, marker] = useAdvancedMarkerRef();
  const iconName = useMemo(
    () => resolveVenueMapIcon(group.deals, now),
    [group.deals, now],
  );
  const showProductIcon =
    iconName !== undefined && isRegisteredProductIcon(iconName);
  const hasActiveDeal = useMemo(
    () => hasAnyDealActiveNow(group.deals, now),
    [group.deals, now],
  );

  const handleMarkerClick = useCallback(() => {
    if (!isSelected) {
      track("map_marker_selected", {
        venue_id: group.venue.id,
        venue_name: group.venue.name,
      });
    }
    onSelect(group.venue.id);
  }, [group.venue.id, group.venue.name, isSelected, onSelect]);

  return (
    <>
      <AdvancedMarker
        ref={markerRef}
        position={{ lat: group.venue.lat, lng: group.venue.lng }}
        onClick={handleMarkerClick}
      >
        {showProductIcon ? (
          <div
            className={`flex h-8 w-8 items-center justify-center rounded-full shadow-md ${
              hasActiveDeal
                ? "border-2 border-accent bg-accent"
                : "bg-slate-300"
            }`}
          >
            <ProductMapIcon
              name={iconName}
              className="text-accent-fg"
              size={16}
            />
          </div>
        ) : (
          <Pin
            background={hasActiveDeal ? "#f59e0b" : "#64748b"}
            borderColor={hasActiveDeal ? "#b45309" : "#475569"}
            glyphColor="#ffffff"
          />
        )}
      </AdvancedMarker>
      {isSelected && marker ? (
        <InfoWindow
          anchor={marker}
          onClose={onClose}
          headerDisabled
          maxWidth={480}
        >
          <VenueMapPopup
            group={group}
            searchDays={searchDays}
            now={now}
            onClose={onClose}
          />
        </InfoWindow>
      ) : null}
    </>
  );
}

function UserLocationMarker({
  userLocation,
  isSelected,
  onSelect,
  onClose,
}: {
  userLocation: UserLocation;
  isSelected: boolean;
  onSelect: () => void;
  onClose: () => void;
}) {
  const [markerRef, marker] = useAdvancedMarkerRef();

  return (
    <>
      <AdvancedMarker
        ref={markerRef}
        position={{ lat: userLocation.lat, lng: userLocation.lng }}
        onClick={onSelect}
      >
        <Pin
          background="#3b82f6"
          borderColor="#2563eb"
          glyphColor="#ffffff"
        />
      </AdvancedMarker>
      {isSelected && marker ? (
        <InfoWindow anchor={marker} onClose={onClose}>
          Your location
        </InfoWindow>
      ) : null}
    </>
  );
}

function MapUnavailablePlaceholder({
  fullScreen,
  message = "Map unavailable — check NEXT_PUBLIC_GOOGLE_MAPS_API_KEY and NEXT_PUBLIC_GOOGLE_MAPS_MAP_ID in your environment.",
}: {
  fullScreen: boolean;
  message?: string;
}) {
  return (
    <div
      className={`flex items-center justify-center bg-surface-muted p-6 text-center text-sm text-muted ${
        fullScreen
          ? "absolute inset-0"
          : "h-[60vh] rounded-xl border border-dashed border-border"
      }`}
    >
      {message}
    </div>
  );
}

function MapLoadingPlaceholder({ fullScreen }: { fullScreen: boolean }) {
  return (
    <div
      className={`flex items-center justify-center bg-background text-sm text-muted ${
        fullScreen ? "absolute inset-0" : "h-[60vh]"
      }`}
    >
      Loading map...
    </div>
  );
}

function SearchMapCanvas({
  mapId,
  venueGroups,
  userLocation,
  searchDays,
  fullScreen,
  onViewportIdle,
  autoFitBounds,
  initialBounds,
  selectedMarker,
  onVenueSelect,
  onUserSelect,
  onInfoWindowClose,
  now,
}: {
  mapId: string;
  venueGroups: VenueGroupedDeals[];
  userLocation: UserLocation | null;
  searchDays: number[];
  fullScreen: boolean;
  onViewportIdle?: (bounds: MapBounds) => void;
  autoFitBounds: boolean;
  initialBounds: MapBounds | null;
  selectedMarker: SelectedMarker;
  onVenueSelect: (venueId: number) => void;
  onUserSelect: () => void;
  onInfoWindowClose: () => void;
  now: Date;
}) {
  const loadingStatus = useApiLoadingStatus();

  if (
    loadingStatus === APILoadingStatus.FAILED ||
    loadingStatus === APILoadingStatus.AUTH_FAILURE
  ) {
    return (
      <MapUnavailablePlaceholder
        fullScreen={fullScreen}
        message="Map unavailable — Google Maps failed to authorize. Check the API key, map ID, and HTTP referrer restrictions."
      />
    );
  }

  if (loadingStatus !== APILoadingStatus.LOADED) {
    return <MapLoadingPlaceholder fullScreen={fullScreen} />;
  }

  return (
    <Map
      mapId={mapId}
      clickableIcons={false}
      colorScheme="DARK"
      defaultCenter={DEFAULT_CENTER}
      defaultZoom={DEFAULT_ZOOM}
      gestureHandling="greedy"
      className={fullScreen ? "h-full w-full" : "h-[60vh] w-full"}
    >
      {autoFitBounds ? (
        <FitBounds venueGroups={venueGroups} userLocation={userLocation} />
      ) : null}

      {!autoFitBounds && initialBounds ? (
        <InitialBounds bounds={initialBounds} />
      ) : null}

      {onViewportIdle ? (
        <ViewportIdleReporter onViewportIdle={onViewportIdle} />
      ) : null}

      {userLocation ? (
        <UserLocationMarker
          userLocation={userLocation}
          isSelected={selectedMarker === "user"}
          onSelect={onUserSelect}
          onClose={onInfoWindowClose}
        />
      ) : null}

      {venueGroups.map((group) => (
        <VenueMarker
          key={group.venue.id}
          group={group}
          searchDays={searchDays}
          now={now}
          isSelected={selectedMarker === group.venue.id}
          onSelect={onVenueSelect}
          onClose={onInfoWindowClose}
        />
      ))}
    </Map>
  );
}

export function SearchMapView({
  venueGroups,
  userLocation,
  isEmpty,
  searchDays = [],
  fullScreen = false,
  onViewportIdle,
  autoFitBounds = true,
  initialBounds = null,
}: SearchMapViewProps) {
  const [selectedMarker, setSelectedMarker] = useState<SelectedMarker>(null);
  const now = useCurrentMinute();

  const handleVenueSelect = useCallback((venueId: number) => {
    setSelectedMarker((current) => (current === venueId ? null : venueId));
  }, []);

  const handleUserSelect = useCallback(() => {
    setSelectedMarker((current) => (current === "user" ? null : "user"));
  }, []);

  const handleInfoWindowClose = useCallback(() => {
    setSelectedMarker(null);
  }, []);

  if (!googleMapsApiKey || !googleMapsMapId) {
    return <MapUnavailablePlaceholder fullScreen={fullScreen} />;
  }

  return (
    <div
      className={
        fullScreen
          ? "absolute inset-0"
          : "relative min-h-[60vh] overflow-hidden rounded-xl border border-border"
      }
    >
      <APIProvider apiKey={googleMapsApiKey}>
        <SearchMapCanvas
          mapId={googleMapsMapId}
          venueGroups={venueGroups}
          userLocation={userLocation}
          searchDays={searchDays}
          fullScreen={fullScreen}
          onViewportIdle={onViewportIdle}
          autoFitBounds={autoFitBounds}
          initialBounds={initialBounds}
          selectedMarker={selectedMarker}
          onVenueSelect={handleVenueSelect}
          onUserSelect={handleUserSelect}
          onInfoWindowClose={handleInfoWindowClose}
          now={now}
        />
      </APIProvider>

      {isEmpty ? (
        <div className="pointer-events-none absolute inset-0 flex items-center justify-center bg-background/70 p-6">
          <p className="max-w-sm rounded-xl border border-dashed border-border bg-surface px-4 py-8 text-center text-sm text-muted shadow-card">
            No deals matched your filters. Try syncing data from DealScraper or
            broadening your search.
          </p>
        </div>
      ) : null}
    </div>
  );
}
