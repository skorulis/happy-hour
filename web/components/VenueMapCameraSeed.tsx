"use client";

import {
  clearVenueMapCameraSeed,
  setVenueMapCameraSeed,
} from "@/lib/search/map-entry";
import { useEffect } from "react";

type VenueMapCameraSeedProps = {
  listPath: string;
  lat: number;
  lng: number;
};

/** Registers venue coordinates so Map nav can center the map on this venue. */
export function VenueMapCameraSeed({
  listPath,
  lat,
  lng,
}: VenueMapCameraSeedProps) {
  useEffect(() => {
    setVenueMapCameraSeed({ listPath, lat, lng });
    return () => {
      clearVenueMapCameraSeed();
    };
  }, [listPath, lat, lng]);

  return null;
}
