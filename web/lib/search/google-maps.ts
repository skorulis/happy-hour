export function bareGooglePlaceId(googleMapId: string): string {
  return googleMapId.replace(/^places\//, "");
}

export function googleMapsPlaceUrl(
  name: string,
  googleMapId: string,
): string {
  const params = new URLSearchParams({
    api: "1",
    query: name,
    query_place_id: bareGooglePlaceId(googleMapId),
  });
  return `https://www.google.com/maps/search/?${params}`;
}
