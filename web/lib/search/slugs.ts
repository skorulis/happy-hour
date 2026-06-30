export const UNKNOWN_SUBURB_SLUG = "unknown";

export function slugify(value: string): string {
  return value
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

export function venuePath(
  suburbName: string | null,
  venueName: string,
): string {
  const suburbSlug = suburbName ? slugify(suburbName) : UNKNOWN_SUBURB_SLUG;
  return `/${suburbSlug}/${slugify(venueName)}`;
}

export function dealAnchorId(dealId: number): string {
  return `deal-${dealId}`;
}
