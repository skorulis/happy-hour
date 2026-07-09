"use client";

import Link from "next/link";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { resolveVenueMapIcon } from "@/lib/search/map-icon";
import {
  AdvancedMarker,
  APIProvider,
  InfoWindow,
  Map,
  Pin,
  useAdvancedMarkerRef,
  useMap,
} from "@vis.gl/react-google-maps";
import type { VenueGroupedDeals } from "@/components/VenueSearchCard";
import {
  formatDealDayBadge,
  formatDealTimeBadge,
  hasAnyDealActiveNow,
  sortDealsActiveFirst,
} from "@/lib/search/schedule";
import { formatDistanceKm } from "@/lib/search/distance";
import {
  boundsFromGoogleMap,
  boundsKey,
  type MapBounds,
} from "@/lib/search/bounds";
import { venuePath } from "@/lib/search/slugs";
import { appendDaysParam } from "@/lib/search/url";
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

function VenuePopup({
  group,
  searchDays = [],
  now,
}: {
  group: VenueGroupedDeals;
  searchDays?: number[];
  now: Date;
}) {
  const previewDeals = sortDealsActiveFirst(group.deals, now).slice(0, 2);
  const dealLabel =
    group.deals.length === 1 ? "1 deal" : `${group.deals.length} deals`;
  const venueHref = appendDaysParam(
    venuePath(group.venue.suburbName, group.venue.name),
    searchDays,
  );

  return (
    <div className="min-w-[10rem] space-y-2 text-sm">
      <div>
        <Link
          href={venueHref}
          className="font-semibold text-amber-700 hover:underline dark:text-amber-400"
        >
          {group.venue.name}
        </Link>
        <p className="text-xs text-zinc-500 dark:text-zinc-400">
          {group.venue.distanceKm !== undefined
            ? `${formatDistanceKm(group.venue.distanceKm)} away · `
            : ""}
          {dealLabel}
        </p>
      </div>

      {previewDeals.length > 0 ? (
        <ul className="space-y-1 border-t border-zinc-200 pt-2 dark:border-zinc-700">
          {previewDeals.map((deal) => {
            const timeBadge = formatDealTimeBadge(deal.schedules);

            return (
              <li key={deal.id} className="text-xs text-zinc-700 dark:text-zinc-300">
                <span className="font-medium">
                  {deal.title || "Untitled deal"}
                </span>
                <span className="ml-1 text-zinc-500 dark:text-zinc-400">
                  · {formatDealDayBadge(deal.schedules)}
                  {timeBadge && timeBadge !== "—" ? ` · ${timeBadge}` : ""}
                </span>
              </li>
            );
          })}
          {group.deals.length > previewDeals.length ? (
            <li className="text-xs text-zinc-500 dark:text-zinc-400">
              +{group.deals.length - previewDeals.length} more
            </li>
          ) : null}
        </ul>
      ) : null}
    </div>
  );
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
    onSelect(group.venue.id);
  }, [group.venue.id, onSelect]);

  return (
    <>
      <AdvancedMarker
        ref={markerRef}
        position={{ lat: group.venue.lat, lng: group.venue.lng }}
        onClick={handleMarkerClick}
      >
        {showProductIcon ? (
          <div
            className={`flex h-8 w-8 items-center justify-center rounded-full border-2 shadow-md ${
              hasActiveDeal
                ? "border-amber-700 bg-amber-500"
                : "border-zinc-500 bg-zinc-400"
            }`}
          >
            <ProductMapIcon name={iconName} className="text-white" size={16} />
          </div>
        ) : (
          <Pin
            background={hasActiveDeal ? "#f59e0b" : "#a1a1aa"}
            borderColor={hasActiveDeal ? "#b45309" : "#71717a"}
            glyphColor="#ffffff"
          />
        )}
      </AdvancedMarker>
      {isSelected ? (
        <InfoWindow anchor={marker} onClose={onClose}>
          <VenuePopup group={group} searchDays={searchDays} now={now} />
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
      {isSelected ? (
        <InfoWindow anchor={marker} onClose={onClose}>
          Your location
        </InfoWindow>
      ) : null}
    </>
  );
}

function MapUnavailablePlaceholder({ fullScreen }: { fullScreen: boolean }) {
  return (
    <div
      className={`flex items-center justify-center bg-zinc-50 p-6 text-center text-sm text-zinc-500 dark:bg-zinc-900 dark:text-zinc-400 ${
        fullScreen
          ? "absolute inset-0"
          : "h-[60vh] rounded-xl border border-dashed border-zinc-300 dark:border-zinc-700"
      }`}
    >
      Map unavailable — check NEXT_PUBLIC_GOOGLE_MAPS_API_KEY and
      NEXT_PUBLIC_GOOGLE_MAPS_MAP_ID in your environment.
    </div>
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
          : "relative min-h-[60vh] overflow-hidden rounded-xl border border-zinc-200 dark:border-zinc-800"
      }
    >
      <APIProvider apiKey={googleMapsApiKey}>
        <Map
          mapId={googleMapsMapId}
          defaultCenter={DEFAULT_CENTER}
          defaultZoom={DEFAULT_ZOOM}
          gestureHandling="greedy"
          className={fullScreen ? "h-full w-full" : "h-[60vh] w-full"}
        >
          {autoFitBounds ? (
            <FitBounds venueGroups={venueGroups} userLocation={userLocation} />
          ) : null}

          {onViewportIdle ? (
            <ViewportIdleReporter onViewportIdle={onViewportIdle} />
          ) : null}

          {userLocation ? (
            <UserLocationMarker
              userLocation={userLocation}
              isSelected={selectedMarker === "user"}
              onSelect={handleUserSelect}
              onClose={handleInfoWindowClose}
            />
          ) : null}

          {venueGroups.map((group) => (
            <VenueMarker
              key={group.venue.id}
              group={group}
              searchDays={searchDays}
              now={now}
              isSelected={selectedMarker === group.venue.id}
              onSelect={handleVenueSelect}
              onClose={handleInfoWindowClose}
            />
          ))}
        </Map>
      </APIProvider>

      {isEmpty ? (
        <div className="pointer-events-none absolute inset-0 flex items-center justify-center bg-white/70 p-6 dark:bg-zinc-950/70">
          <p className="max-w-sm rounded-xl border border-dashed border-zinc-300 bg-white px-4 py-8 text-center text-sm text-zinc-500 shadow-sm dark:border-zinc-700 dark:bg-zinc-950 dark:text-zinc-400">
            No deals matched your filters. Try syncing data from DealScraper or
            broadening your search.
          </p>
        </div>
      ) : null}
    </div>
  );
}
