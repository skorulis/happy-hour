import { KM_PER_DEG_LAT } from "./bounds";

/**
 * Extra distance beyond the outermost suburb centre. Suburbs contribute a
 * single point, so the region reaches past them on every side.
 */
export const REGION_BUFFER_KM = 2;

export type SuburbCenter = {
  lat: number | null | undefined;
  lng: number | null | undefined;
};

/** Map framing for a region, stored the same way as suburbs. */
export type RegionGeo = {
  lat: number;
  lng: number;
  sqkm: number;
};

function isFiniteCoordinate(value: number | null | undefined): value is number {
  return typeof value === "number" && Number.isFinite(value);
}

/**
 * Centre and area for a region, derived from the centres of its suburbs.
 *
 * The centre is the midpoint of the suburb bounding box, and the area is the
 * circle whose square bounding box (as built by `boundsFromCenterRadiusKm`)
 * covers that box plus `REGION_BUFFER_KM`. Returns null when no suburb has
 * usable coordinates, which leaves the map on its default camera.
 */
export function regionGeoFromSuburbCenters(
  centers: readonly SuburbCenter[],
): RegionGeo | null {
  let north = -Infinity;
  let south = Infinity;
  let east = -Infinity;
  let west = Infinity;
  let found = 0;

  for (const center of centers) {
    const { lat, lng } = center;
    if (!isFiniteCoordinate(lat) || !isFiniteCoordinate(lng)) {
      continue;
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      continue;
    }

    north = Math.max(north, lat);
    south = Math.min(south, lat);
    east = Math.max(east, lng);
    west = Math.min(west, lng);
    found += 1;
  }

  if (found === 0) {
    return null;
  }

  const lat = (north + south) / 2;
  const lng = (east + west) / 2;

  const latHalfSpanKm = ((north - south) / 2) * KM_PER_DEG_LAT;
  const cosLat = Math.abs(Math.cos((lat * Math.PI) / 180));
  const lngHalfSpanKm = ((east - west) / 2) * KM_PER_DEG_LAT * cosLat;

  // The map turns this radius back into a square box of +/- radius in both
  // directions, so the larger half-span covers the region without over-zooming.
  const radiusKm = Math.max(latHalfSpanKm, lngHalfSpanKm) + REGION_BUFFER_KM;

  return {
    lat,
    lng,
    sqkm: Math.PI * radiusKm * radiusKm,
  };
}
