import type { Metadata } from "next";
import { headers } from "next/headers";
import { notFound, permanentRedirect, redirect } from "next/navigation";
import { VenuePageContent } from "@/components/VenuePageContent";
import { canManageVenue } from "@/lib/admin";
import { auth } from "@/lib/auth";
import { stripDaySuffix } from "@/lib/search/day-path";
import { getVenueDetailBySlug } from "@/lib/search/queries";
import { venuePath, venueRedirectPath } from "@/lib/search/slugs";
import { initialVenueDay, legacyDaysRedirectHref } from "@/lib/search/url";

type VenuePageProps = {
  params: Promise<{ suburb: string; venueSlug: string }>;
  searchParams: Promise<{ days?: string }>;
};

export async function generateMetadata({
  params,
}: VenuePageProps): Promise<Metadata> {
  const { suburb, venueSlug: rawVenueSlug } = await params;
  const { base: venueSlug } = stripDaySuffix(rawVenueSlug);
  const venue = await getVenueDetailBySlug(suburb, venueSlug);

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
  const { base: venueSlug, day: pathDay } = stripDaySuffix(rawVenueSlug);

  const search = new URLSearchParams();
  if (daysParam) {
    search.set("days", daysParam);
  }
  const daysRedirect = legacyDaysRedirectHref(
    `/${suburb}/${rawVenueSlug}`,
    search,
  );
  if (daysRedirect) {
    permanentRedirect(daysRedirect);
  }

  const redirectPath = venueRedirectPath(suburb, venueSlug, {
    day: pathDay ?? undefined,
  });
  if (redirectPath) {
    redirect(redirectPath);
  }

  const venue = await getVenueDetailBySlug(suburb, venueSlug);

  if (!venue) {
    notFound();
  }

  const initialSelectedDay = initialVenueDay(
    pathDay !== null ? [pathDay] : [],
  );

  const session = await auth.api.getSession({
    headers: await headers(),
  });
  const showAdminLink = session
    ? await canManageVenue(session.user, venue.id)
    : false;

  return (
    <VenuePageContent
      venue={venue}
      initialSelectedDay={initialSelectedDay}
      showAdminLink={showAdminLink}
    />
  );
}
