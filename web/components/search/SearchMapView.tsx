"use client";

import Link from "next/link";
import { useEffect } from "react";
import L from "leaflet";
import {
  CircleMarker,
  MapContainer,
  Marker,
  Popup,
  TileLayer,
  useMap,
} from "react-leaflet";
import "leaflet/dist/leaflet.css";
import type { VenueGroupedDeals } from "@/components/VenueSearchCard";
import {
  formatDealDayBadge,
  formatDealTimeBadge,
} from "@/lib/search/schedule";
import { venuePath } from "@/lib/search/slugs";
import { appendDaysParam } from "@/lib/search/url";

const DEFAULT_CENTER: [number, number] = [-33.87, 151.21];
const DEFAULT_ZOOM = 11;

const defaultIcon = L.icon({
  iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  iconRetinaUrl:
    "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41],
});

L.Marker.prototype.options.icon = defaultIcon;

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

function FitBounds({
  venueGroups,
  userLocation,
}: {
  venueGroups: VenueGroupedDeals[];
  userLocation: UserLocation | null;
}) {
  const map = useMap();

  useEffect(() => {
    const points: [number, number][] = venueGroups.map((group) => [
      group.venue.lat,
      group.venue.lng,
    ]);

    if (userLocation) {
      points.push([userLocation.lat, userLocation.lng]);
    }

    if (points.length === 0) {
      map.setView(DEFAULT_CENTER, DEFAULT_ZOOM);
      return;
    }

    if (points.length === 1) {
      map.setView(points[0], 14);
      return;
    }

    map.fitBounds(L.latLngBounds(points), { padding: [48, 48] });
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
        <p className="text-xs text-zinc-500 dark:text-zinc-400">{dealLabel}</p>
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

export function SearchMapView({
  venueGroups,
  userLocation,
  isEmpty,
  searchDays = [],
}: SearchMapViewProps) {
  return (
    <div className="relative min-h-[60vh] overflow-hidden rounded-xl border border-zinc-200 dark:border-zinc-800">
      <MapContainer
        center={DEFAULT_CENTER}
        zoom={DEFAULT_ZOOM}
        className="h-[60vh] w-full"
        scrollWheelZoom
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <FitBounds venueGroups={venueGroups} userLocation={userLocation} />

        {userLocation ? (
          <CircleMarker
            center={[userLocation.lat, userLocation.lng]}
            radius={8}
            pathOptions={{
              color: "#2563eb",
              fillColor: "#3b82f6",
              fillOpacity: 1,
              weight: 2,
            }}
          >
            <Popup>Your location</Popup>
          </CircleMarker>
        ) : null}

        {venueGroups.map((group) => (
          <Marker
            key={group.venue.id}
            position={[group.venue.lat, group.venue.lng]}
          >
            <Popup>
              <VenuePopup group={group} searchDays={searchDays} />
            </Popup>
          </Marker>
        ))}
      </MapContainer>

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
