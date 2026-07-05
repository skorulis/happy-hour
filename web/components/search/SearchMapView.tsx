"use client";

import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
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
} from "@/lib/search/schedule";
import { formatDistanceKm } from "@/lib/search/distance";
import { venuePath } from "@/lib/search/slugs";
import { appendDaysParam } from "@/lib/search/url";

const DEFAULT_CENTER = { lat: -33.87, lng: 151.21 };
const DEFAULT_ZOOM = 11;

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

function VenuePopup({
  group,
  searchDays = [],
}: {
  group: VenueGroupedDeals;
  searchDays?: number[];
}) {
  const previewDeals = group.deals.slice(0, 2);
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

function VenueMarker({
  group,
  searchDays,
  isSelected,
  onSelect,
  onClose,
}: {
  group: VenueGroupedDeals;
  searchDays: number[];
  isSelected: boolean;
  onSelect: (venueId: number) => void;
  onClose: () => void;
}) {
  const [markerRef, marker] = useAdvancedMarkerRef();

  const handleMarkerClick = useCallback(() => {
    onSelect(group.venue.id);
  }, [group.venue.id, onSelect]);

  return (
    <>
      <AdvancedMarker
        ref={markerRef}
        position={{ lat: group.venue.lat, lng: group.venue.lng }}
        onClick={handleMarkerClick}
      />
      {isSelected ? (
        <InfoWindow anchor={marker} onClose={onClose}>
          <VenuePopup group={group} searchDays={searchDays} />
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

function MapUnavailablePlaceholder() {
  return (
    <div className="flex h-[60vh] items-center justify-center rounded-xl border border-dashed border-zinc-300 bg-zinc-50 p-6 text-center text-sm text-zinc-500 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-400">
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
}: SearchMapViewProps) {
  const [selectedMarker, setSelectedMarker] = useState<SelectedMarker>(null);

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
    return <MapUnavailablePlaceholder />;
  }

  return (
    <div className="relative min-h-[60vh] overflow-hidden rounded-xl border border-zinc-200 dark:border-zinc-800">
      <APIProvider apiKey={googleMapsApiKey}>
        <Map
          mapId={googleMapsMapId}
          defaultCenter={DEFAULT_CENTER}
          defaultZoom={DEFAULT_ZOOM}
          gestureHandling="greedy"
          className="h-[60vh] w-full"
        >
          <FitBounds venueGroups={venueGroups} userLocation={userLocation} />

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
