import { describe, expect, it } from "vitest";
import { boundsFromCenterRadiusKm } from "./bounds";
import { regionMapRadiusKm } from "./nearby-radius";
import { REGION_BUFFER_KM, regionGeoFromSuburbCenters } from "./region-geo";

const SYDNEY_SUBURBS = [
  { lat: -33.86, lng: 151.21 },
  { lat: -33.79, lng: 151.28 },
  { lat: -34.05, lng: 151.15 },
  { lat: -33.87, lng: 150.93 },
];

describe("regionGeoFromSuburbCenters", () => {
  it("returns null when no suburb has coordinates", () => {
    expect(regionGeoFromSuburbCenters([])).toBeNull();
    expect(
      regionGeoFromSuburbCenters([
        { lat: null, lng: null },
        { lat: -33.86, lng: undefined },
        { lat: Number.NaN, lng: 151.2 },
      ]),
    ).toBeNull();
  });

  it("centers on the midpoint of the suburb bounding box", () => {
    const geo = regionGeoFromSuburbCenters(SYDNEY_SUBURBS);

    expect(geo).not.toBeNull();
    expect(geo!.lat).toBeCloseTo((-33.79 + -34.05) / 2);
    expect(geo!.lng).toBeCloseTo((151.28 + 150.93) / 2);
  });

  it("ignores suburbs with missing or out-of-range coordinates", () => {
    const geo = regionGeoFromSuburbCenters([
      ...SYDNEY_SUBURBS,
      { lat: null, lng: 151.2 },
      { lat: -91, lng: 151.2 },
      { lat: -33.9, lng: 181 },
    ]);

    expect(geo).toEqual(regionGeoFromSuburbCenters(SYDNEY_SUBURBS));
  });

  it("frames a single suburb with just the buffer", () => {
    const geo = regionGeoFromSuburbCenters([{ lat: -33.86, lng: 151.21 }]);

    expect(geo).not.toBeNull();
    expect(geo!.lat).toBeCloseTo(-33.86);
    expect(geo!.lng).toBeCloseTo(151.21);
    expect(regionMapRadiusKm(geo!.sqkm)).toBeCloseTo(REGION_BUFFER_KM);
  });

  it("stores an area the map turns back into a covering viewport", () => {
    const geo = regionGeoFromSuburbCenters(SYDNEY_SUBURBS)!;
    const bounds = boundsFromCenterRadiusKm(
      geo.lat,
      geo.lng,
      regionMapRadiusKm(geo.sqkm),
    );

    expect(bounds).not.toBeNull();
    for (const { lat, lng } of SYDNEY_SUBURBS) {
      expect(lat).toBeLessThan(bounds!.north);
      expect(lat).toBeGreaterThan(bounds!.south);
      expect(lng).toBeLessThan(bounds!.east);
      expect(lng).toBeGreaterThan(bounds!.west);
    }
  });

  it("grows with the spread of its suburbs", () => {
    const tight = regionGeoFromSuburbCenters([
      { lat: -33.86, lng: 151.21 },
      { lat: -33.88, lng: 151.23 },
    ])!;
    const spread = regionGeoFromSuburbCenters(SYDNEY_SUBURBS)!;

    expect(spread.sqkm).toBeGreaterThan(tight.sqkm);
  });
});
