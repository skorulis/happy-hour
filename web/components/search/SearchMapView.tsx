"use client";

import {
  useCallback,
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import { Heart } from "lucide-react";
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
import {
  MarkerClusterer,
  MarkerClustererEvents,
  MarkerUtils,
  type Marker,
  type Renderer,
} from "@googlemaps/markerclusterer";
import type { VenueGroupedDeals } from "@/components/VenueSearchCard";
import { VenueMapPopup } from "@/components/search/VenueMapPopup";
import { track } from "@/lib/analytics/client";
import { useFavorites } from "@/lib/favorites/useFavorites";
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

const CLUSTER_ACCENT = "#f59e0b";
const CLUSTER_ACCENT_BORDER = "#b45309";
const CLUSTER_LABEL = "#081426";

const venueClusterRenderer: Renderer = {
  render({ count, position }, _stats, map) {
    const size = count < 10 ? 40 : count < 50 ? 48 : 56;

    if (MarkerUtils.isAdvancedMarkerAvailable(map)) {
      const content = document.createElement("div");
      content.style.width = `${size}px`;
      content.style.height = `${size}px`;
      content.style.borderRadius = "9999px";
      content.style.background = CLUSTER_ACCENT;
      content.style.border = `2px solid ${CLUSTER_ACCENT_BORDER}`;
      content.style.boxShadow = "0 2px 6px rgba(0,0,0,0.35)";
      content.style.display = "flex";
      content.style.alignItems = "center";
      content.style.justifyContent = "center";
      content.style.color = CLUSTER_LABEL;
      content.style.fontSize = count < 10 ? "13px" : "14px";
      content.style.fontWeight = "700";
      content.style.fontFamily = "system-ui, sans-serif";
      content.textContent = String(count);

      return new google.maps.marker.AdvancedMarkerElement({
        position,
        content,
        zIndex: 1000 + count,
      });
    }

    const svg = window.btoa(`
      <svg fill="${CLUSTER_ACCENT}" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 240">
        <circle cx="120" cy="120" opacity=".9" r="70" />
        <circle cx="120" cy="120" opacity=".4" r="90" />
        <circle cx="120" cy="120" opacity=".2" r="110" />
      </svg>`);

    return new google.maps.Marker({
      position,
      icon: {
        url: `data:image/svg+xml;base64,${svg}`,
        scaledSize: new google.maps.Size(size, size),
      },
      label: {
        text: String(count),
        color: CLUSTER_LABEL,
        fontSize: "12px",
        fontWeight: "700",
      },
      zIndex: 1000 + count,
    });
  },
};

const googleMapsApiKey = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY;
const googleMapsMapId = process.env.NEXT_PUBLIC_GOOGLE_MAPS_MAP_ID;

type UserLocation = {
  lat: number;
  lng: number;
};

type SearchMapViewProps = {
  venueGroups: VenueGroupedDeals[];
  userLocation: UserLocation | null;
  searchDays?: number[];
  fullScreen?: boolean;
  onViewportIdle?: (bounds: MapBounds) => void;
  autoFitBounds?: boolean;
  initialBounds?: MapBounds | null;
  onUserMapInteract?: () => void;
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

function MapInteractionReporter({
  onUserMapInteract,
  initialBounds,
}: {
  onUserMapInteract: () => void;
  initialBounds: MapBounds | null;
}) {
  const map = useMap();
  const onUserMapInteractRef = useRef(onUserMapInteract);
  const settledRef = useRef(false);
  const initialBoundsKey = initialBounds ? boundsKey(initialBounds) : null;

  // Layout effect so this runs before sibling InitialBounds useEffects fitBounds.
  useLayoutEffect(() => {
    settledRef.current = false;
  }, [initialBoundsKey]);

  useEffect(() => {
    onUserMapInteractRef.current = onUserMapInteract;
  }, [onUserMapInteract]);

  useEffect(() => {
    if (!map) {
      return;
    }

    settledRef.current = false;

    function reportInteract() {
      onUserMapInteractRef.current();
    }

    const idleListener = map.addListener("idle", () => {
      settledRef.current = true;
    });
    const dragListener = map.addListener("dragstart", reportInteract);
    const clickListener = map.addListener("click", reportInteract);
    const zoomListener = map.addListener("zoom_changed", () => {
      if (settledRef.current) {
        reportInteract();
      }
    });

    return () => {
      idleListener.remove();
      dragListener.remove();
      clickListener.remove();
      zoomListener.remove();
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
  setMarkerRef,
}: {
  group: VenueGroupedDeals;
  searchDays: number[];
  now: Date;
  isSelected: boolean;
  onSelect: (venueId: number) => void;
  onClose: () => void;
  setMarkerRef: (marker: Marker | null, venueId: number) => void;
}) {
  const [marker, setMarker] = useState<google.maps.marker.AdvancedMarkerElement | null>(
    null,
  );
  const { isFavorite } = useFavorites();
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
  const hasFavoriteDeal = group.deals.some((deal) => isFavorite(deal.id));

  const handleMarkerClick = useCallback(() => {
    if (!isSelected) {
      track("map_marker_selected", {
        venue_id: group.venue.id,
        venue_name: group.venue.name,
      });
    }
    onSelect(group.venue.id);
  }, [group.venue.id, group.venue.name, isSelected, onSelect]);

  const handleMarkerRef = useCallback(
    (instance: google.maps.marker.AdvancedMarkerElement | null) => {
      setMarker(instance);
      setMarkerRef(instance, group.venue.id);
    },
    [group.venue.id, setMarkerRef],
  );

  const position = useMemo(
    () => ({ lat: group.venue.lat, lng: group.venue.lng }),
    [group.venue.lat, group.venue.lng],
  );

  const markerVisible = marker != null && MarkerUtils.getVisible(marker);

  return (
    <>
      <AdvancedMarker
        ref={handleMarkerRef}
        position={position}
        onClick={handleMarkerClick}
      >
        {hasFavoriteDeal ? (
          <div className="relative flex h-10 w-10 items-center justify-center">
            <Heart
              aria-hidden
              className={`absolute inset-0 h-10 w-10 drop-shadow-md ${
                hasActiveDeal
                  ? "fill-accent text-accent"
                  : "fill-slate-300 text-slate-300"
              }`}
              strokeWidth={1.5}
            />
            {showProductIcon ? (
              <ProductMapIcon
                name={iconName}
                className="relative z-10 text-accent-fg"
                size={16}
              />
            ) : null}
          </div>
        ) : showProductIcon ? (
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
      {isSelected && marker && markerVisible ? (
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

function ClusteredVenueMarkers({
  venueGroups,
  searchDays,
  now,
  selectedMarker,
  onVenueSelect,
  onInfoWindowClose,
}: {
  venueGroups: VenueGroupedDeals[];
  searchDays: number[];
  now: Date;
  selectedMarker: SelectedMarker;
  onVenueSelect: (venueId: number) => void;
  onInfoWindowClose: () => void;
}) {
  const map = useMap();
  const [markers, setMarkers] = useState<Record<string, Marker>>({});
  // Create in an effect (not useMemo) so React Strict Mode / remounts get a
  // fresh clusterer. useMemo + setMap(null) cleanup left a dead instance that
  // stopped clustering while AdvancedMarkers stayed on the map.
  const clustererRef = useRef<MarkerClusterer | null>(null);

  useEffect(() => {
    if (!map) {
      return;
    }

    const instance = new MarkerClusterer({
      map,
      renderer: venueClusterRenderer,
    });
    clustererRef.current = instance;

    return () => {
      instance.clearMarkers();
      (instance as unknown as google.maps.OverlayView).setMap(null);
      if (clustererRef.current === instance) {
        clustererRef.current = null;
      }
    };
  }, [map]);

  useEffect(() => {
    const clusterer = clustererRef.current;
    if (!clusterer) {
      return;
    }

    clusterer.clearMarkers();
    clusterer.addMarkers(Object.values(markers));
  }, [map, markers]);

  useEffect(() => {
    const clusterer = clustererRef.current;
    if (!clusterer) {
      return;
    }

    const listener = google.maps.event.addListener(
      clusterer,
      MarkerClustererEvents.CLUSTERING_END,
      () => {
        if (typeof selectedMarker !== "number") {
          return;
        }

        const marker = markers[String(selectedMarker)];
        if (marker && !MarkerUtils.getVisible(marker)) {
          onInfoWindowClose();
        }
      },
    );

    return () => {
      listener.remove();
    };
  }, [map, markers, onInfoWindowClose, selectedMarker]);

  const setMarkerRef = useCallback((marker: Marker | null, venueId: number) => {
    const key = String(venueId);
    setMarkers((current) => {
      if (marker) {
        // Replace when AdvancedMarker recreates the element for the same venue.
        if (current[key] === marker) {
          return current;
        }
        return { ...current, [key]: marker };
      }

      if (!current[key]) {
        return current;
      }

      const rest = { ...current };
      delete rest[key];
      return rest;
    });
  }, []);

  return (
    <>
      {venueGroups.map((group) => (
        <VenueMarker
          key={group.venue.id}
          group={group}
          searchDays={searchDays}
          now={now}
          isSelected={selectedMarker === group.venue.id}
          onSelect={onVenueSelect}
          onClose={onInfoWindowClose}
          setMarkerRef={setMarkerRef}
        />
      ))}
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
  onUserMapInteract,
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
  onUserMapInteract?: () => void;
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

      {onUserMapInteract ? (
        <MapInteractionReporter
          onUserMapInteract={onUserMapInteract}
          initialBounds={initialBounds}
        />
      ) : null}

      {userLocation ? (
        <UserLocationMarker
          userLocation={userLocation}
          isSelected={selectedMarker === "user"}
          onSelect={onUserSelect}
          onClose={onInfoWindowClose}
        />
      ) : null}

      <ClusteredVenueMarkers
        venueGroups={venueGroups}
        searchDays={searchDays}
        now={now}
        selectedMarker={selectedMarker}
        onVenueSelect={onVenueSelect}
        onInfoWindowClose={onInfoWindowClose}
      />
    </Map>
  );
}

export function SearchMapView({
  venueGroups,
  userLocation,
  searchDays = [],
  fullScreen = false,
  onViewportIdle,
  autoFitBounds = true,
  initialBounds = null,
  onUserMapInteract,
}: SearchMapViewProps) {
  const [selectedMarker, setSelectedMarker] = useState<SelectedMarker>(null);
  const now = useCurrentMinute();
  const onUserMapInteractRef = useRef(onUserMapInteract);

  useEffect(() => {
    onUserMapInteractRef.current = onUserMapInteract;
  }, [onUserMapInteract]);

  const handleVenueSelect = useCallback((venueId: number) => {
    onUserMapInteractRef.current?.();
    setSelectedMarker((current) => (current === venueId ? null : venueId));
  }, []);

  const handleUserSelect = useCallback(() => {
    onUserMapInteractRef.current?.();
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
          onUserMapInteract={onUserMapInteract}
          autoFitBounds={autoFitBounds}
          initialBounds={initialBounds}
          selectedMarker={selectedMarker}
          onVenueSelect={handleVenueSelect}
          onUserSelect={handleUserSelect}
          onInfoWindowClose={handleInfoWindowClose}
          now={now}
        />
      </APIProvider>
    </div>
  );
}
