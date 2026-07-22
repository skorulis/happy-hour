export const UNKNOWN_SUBURB_SLUG = "unknown";
export const NEARBY_WHERE_SLUG = "nearby";

const POSTCODE_SUFFIX_RE = /^(.+)-(\d{4})$/;

export function slugify(value: string): string {
  return value
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

export function suburbWhereSlug(
  name: string,
  postcode: string | null | undefined,
): string {
  const nameSlug = slugify(name);
  const trimmedPostcode = postcode?.trim();
  if (trimmedPostcode) {
    return `${nameSlug}-${trimmedPostcode}`;
  }
  return nameSlug;
}

export function suburbWherePath(
  name: string,
  postcode: string | null | undefined,
): string {
  return `/${suburbWhereSlug(name, postcode)}`;
}

export type ParsedSuburbWhereSlug = {
  nameSlug: string;
  postcode: string | null;
};

export function parseSuburbWhereSlug(slug: string): ParsedSuburbWhereSlug {
  const trimmed = slug.trim().toLowerCase();
  const match = POSTCODE_SUFFIX_RE.exec(trimmed);
  if (match) {
    return { nameSlug: match[1]!, postcode: match[2]! };
  }
  return { nameSlug: trimmed, postcode: null };
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

export function regionSlug(name: string): string {
  return slugify(name);
}

export function regionPath(name: string): string {
  return `/${regionSlug(name)}`;
}

export function regionAllSuburbsPath(name: string): string {
  return `/${regionSlug(name)}/all-suburbs`;
}
