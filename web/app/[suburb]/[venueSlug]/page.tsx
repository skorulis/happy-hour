import type { Metadata } from "next";
import { headers } from "next/headers";
import { notFound } from "next/navigation";
import { VenuePageContent } from "@/components/VenuePageContent";
import { canManageVenue } from "@/lib/admin";
import { auth } from "@/lib/auth";
import { getVenueDetailBySlug } from "@/lib/search/queries";
import { venuePath } from "@/lib/search/slugs";
import { initialVenueDay, parseDaysParam } from "@/lib/search/url";

type VenuePageProps = {
  params: Promise<{ suburb: string; venueSlug: string }>;
  searchParams: Promise<{ days?: string }>;
};

export async function generateMetadata({
  params,
}: VenuePageProps): Promise<Metadata> {
  const { suburb, venueSlug } = await params;
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
  const { suburb, venueSlug } = await params;
  const { days: daysParam } = await searchParams;
  const venue = await getVenueDetailBySlug(suburb, venueSlug);

  if (!venue) {
    notFound();
  }

  const initialSelectedDay = initialVenueDay(parseDaysParam(daysParam ?? null));

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
