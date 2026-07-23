import type { Metadata } from "next";
import { headers } from "next/headers";
import { notFound, permanentRedirect, redirect } from "next/navigation";
import { VenuePageContent } from "@/components/VenuePageContent";
import { canManageVenue } from "@/lib/admin";
import { auth } from "@/lib/auth";
import { dayNumberToHash, stripDaySuffix } from "@/lib/search/day-path";
import { getVenueDetailBySlug } from "@/lib/search/queries";
import { venuePath, venueRedirectPath } from "@/lib/search/slugs";
import { parseDaysParam } from "@/lib/search/url";

type VenuePageProps = {
  params: Promise<{ suburb: string; venueSlug: string }>;
  searchParams: Promise<{ days?: string }>;
};

export async function generateMetadata({
  params,
}: VenuePageProps): Promise<Metadata> {
  const { suburb, venueSlug: rawVenueSlug } = await params;
  const { base: venueSlug } = stripDaySuffix(rawVenueSlug);
  const venue =
    (await getVenueDetailBySlug(suburb, rawVenueSlug)) ??
    (await getVenueDetailBySlug(suburb, venueSlug));

  if (!venue) {
    return {};
  }

  const dealCount = venue.deals.length;
  const description =
    dealCount > 0
      ? `Browse ${dealCount} happy hour ${dealCount === 1 ? "deal" : "deals"} at ${venue.name}${venue.suburbName ? ` in ${venue.suburbName}` : ""}.`
      : `Happy hour deals and specials at ${venue.name}${venue.suburbName ? ` in ${venue.suburbName}` : ""}.`;

  const title = `${venue.name}${venue.suburbName ? `, ${venue.suburbName}` : ""}`;
  const ogImages = venue.heroImage ? [{ url: venue.heroImage }] : undefined;

  return {
    title,
    description,
    alternates: {
      canonical: venuePath(venue.suburbName, venue.name),
    },
    openGraph: {
      title,
      description,
      ...(ogImages ? { images: ogImages } : {}),
    },
    twitter: {
      card: ogImages ? "summary_large_image" : "summary",
      title,
      description,
      ...(ogImages ? { images: ogImages.map((image) => image.url) } : {}),
    },
  };
}

export default async function VenuePage({ params, searchParams }: VenuePageProps) {
  const { suburb, venueSlug: rawVenueSlug } = await params;
  const { days: daysParam } = await searchParams;
  const { base: pathBase, day: pathDay } = stripDaySuffix(rawVenueSlug);

  // Legacy path-suffixed venue URLs → canonical path + day hash.
  if (pathDay !== null) {
    const venue = await getVenueDetailBySlug(suburb, pathBase);
    if (venue) {
      const hash = dayNumberToHash(pathDay) ?? "";
      permanentRedirect(`/${suburb}/${pathBase}${hash}`);
    }
  }

  // Legacy ?days= query → day hash (or bare path for multi-day).
  if (daysParam !== undefined) {
    const days = parseDaysParam(daysParam);
    const hash =
      days.length === 1 ? (dayNumberToHash(days[0]!) ?? "") : "";
    permanentRedirect(`/${suburb}/${rawVenueSlug}${hash}`);
  }

  const redirectPath = venueRedirectPath(suburb, rawVenueSlug);
  if (redirectPath) {
    redirect(redirectPath);
  }

  const venue = await getVenueDetailBySlug(suburb, rawVenueSlug);

  if (!venue) {
    notFound();
  }

  const session = await auth.api.getSession({
    headers: await headers(),
  });
  const showAdminLink = session
    ? await canManageVenue(session.user, venue.id)
    : false;

  return (
    <VenuePageContent venue={venue} showAdminLink={showAdminLink} />
  );
}
