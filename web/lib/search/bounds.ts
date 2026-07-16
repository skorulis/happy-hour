export type MapBounds = {
  north: number;
  south: number;
  east: number;
  west: number;
};

export function isValidBounds(bounds: MapBounds): boolean {
  const { north, south, east, west } = bounds;

  if (
    !Number.isFinite(north) ||
    !Number.isFinite(south) ||
    !Number.isFinite(east) ||
    !Number.isFinite(west)
  ) {
    return false;
  }

  if (south >= north || west >= east) {
    return false;
  }

  if (south < -90 || north > 90 || west < -180 || east > 180) {
    return false;
  }

  return true;
}

export function boundsKey(bounds: MapBounds): string {
  return `${bounds.north},${bounds.south},${bounds.east},${bounds.west}`;
}

export function boundsToApiParams(bounds: MapBounds): URLSearchParams {
  const params = new URLSearchParams();
  params.set("north", String(bounds.north));
  params.set("south", String(bounds.south));
  params.set("east", String(bounds.east));
  params.set("west", String(bounds.west));
  return params;
}

function parseCoordinate(value: string | null): number | null {
  if (value === null || value.trim() === "") {
    return null;
  }

  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

export function parseBoundsParams(
  params: URLSearchParams,
): MapBounds | "invalid" | null {
  const north = parseCoordinate(params.get("north"));
  const south = parseCoordinate(params.get("south"));
  const east = parseCoordinate(params.get("east"));
  const west = parseCoordinate(params.get("west"));

  const values = [north, south, east, west];
  const hasAny = values.some((value) => value !== null);
  const hasAll = values.every((value) => value !== null);

  if (!hasAny) {
    return null;
  }

  if (!hasAll) {
    return "invalid";
  }

  const bounds: MapBounds = {
    north: north!,
    south: south!,
    east: east!,
    west: west!,
  };

  return isValidBounds(bounds) ? bounds : "invalid";
}

export function boundsFromGoogleMap(map: google.maps.Map): MapBounds | null {
  const googleBounds = map.getBounds();
  if (!googleBounds) {
    return null;
  }

  const northEast = googleBounds.getNorthEast();
  const southWest = googleBounds.getSouthWest();

  const bounds: MapBounds = {
    north: northEast.lat(),
    south: southWest.lat(),
    east: northEast.lng(),
    west: southWest.lng(),
  };

  return isValidBounds(bounds) ? bounds : null;
}

const KM_PER_DEG_LAT = 111;

/**
 * Approximate bounding box for a circle of `radiusKm` around a point.
 * Used to seed the map viewport to match circular list search areas.
 */
export function boundsFromCenterRadiusKm(
  lat: number,
  lng: number,
  radiusKm: number,
): MapBounds | null {
  if (
    !Number.isFinite(lat) ||
    !Number.isFinite(lng) ||
    !Number.isFinite(radiusKm) ||
    radiusKm <= 0 ||
    lat < -90 ||
    lat > 90 ||
    lng < -180 ||
    lng > 180
  ) {
    return null;
  }

  const latDelta = radiusKm / KM_PER_DEG_LAT;
  const cosLat = Math.cos((lat * Math.PI) / 180);
  const lngDelta =
    Math.abs(cosLat) < 1e-6 ? 180 : radiusKm / (KM_PER_DEG_LAT * Math.abs(cosLat));

  const bounds: MapBounds = {
    north: Math.min(90, lat + latDelta),
    south: Math.max(-90, lat - latDelta),
    east: Math.min(180, lng + lngDelta),
    west: Math.max(-180, lng - lngDelta),
  };

  return isValidBounds(bounds) ? bounds : null;
}
