import { appendDayToPath } from "@/lib/search/day-path";

export const UNKNOWN_SUBURB_SLUG = "unknown";
export const NEARBY_WHERE_SLUG = "nearby";

const POSTCODE_SUFFIX_RE = /^(.+)-(\d{4})$/;

export const SUBURB_WHERE_SLUG_ALIASES: Readonly<Record<string, string>> = {
  "sydney-2000": "sydney-cbd-2000",
};

export const VENUE_SUBURB_SLUG_ALIASES: Readonly<Record<string, string>> = {
  sydney: "sydney-cbd",
};

export function resolveSuburbWhereSlug(slug: string): string {
  const normalized = slug.trim().toLowerCase();
  return SUBURB_WHERE_SLUG_ALIASES[normalized] ?? normalized;
}

export function resolveVenueSuburbSlug(slug: string): string {
  const normalized = slug.trim().toLowerCase();
  return VENUE_SUBURB_SLUG_ALIASES[normalized] ?? normalized;
}

function singleDayFromLegacyParam(value: string | undefined): number | null {
  if (!value) {
    return null;
  }
  const days = value
    .split(",")
    .map((part) => Number(part.trim()))
    .filter((day) => Number.isFinite(day) && day >= 1 && day <= 7);
  return days.length === 1 ? days[0]! : null;
}

function hrefWithOptionalQuery(
  path: string,
  searchParams?: { q?: string },
): string {
  const params = new URLSearchParams();
  if (searchParams?.q) {
    params.set("q", searchParams.q);
  }
  const query = params.toString();
  return query ? `${path}?${query}` : path;
}

export function suburbWhereRedirectPath(
  whereSlug: string,
  searchParams?: { day?: number; days?: string; q?: string },
): string | null {
  const normalized = whereSlug.trim().toLowerCase();
  const canonical = SUBURB_WHERE_SLUG_ALIASES[normalized];
  if (!canonical) {
    return null;
  }

  const day =
    searchParams?.day ?? singleDayFromLegacyParam(searchParams?.days) ?? null;
  const path = appendDayToPath(
    `/${canonical}`,
    day !== null ? [day] : [],
  );

  return hrefWithOptionalQuery(path, searchParams);
}

export function suburbMapRedirectPath(whereSlug: string): string | null {
  const normalized = whereSlug.trim().toLowerCase();
  const canonical = SUBURB_WHERE_SLUG_ALIASES[normalized];
  if (!canonical) {
    return null;
  }
  return `/${canonical}/map`;
}

export function venueRedirectPath(
  suburbSlug: string,
  venueSlug: string,
  searchParams?: { day?: number; days?: string },
): string | null {
  const normalized = suburbSlug.trim().toLowerCase();
  const canonical = VENUE_SUBURB_SLUG_ALIASES[normalized];
  if (!canonical) {
    return null;
  }

  const day =
    searchParams?.day ?? singleDayFromLegacyParam(searchParams?.days) ?? null;
  return appendDayToPath(
    `/${canonical}/${venueSlug}`,
    day !== null ? [day] : [],
  );
}

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

export function regionStatisticsPath(name: string): string {
  return `/${regionSlug(name)}/statistics`;
}
