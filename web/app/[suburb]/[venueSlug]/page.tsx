import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { VenuePageContent } from "@/components/VenuePageContent";
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

  return {
    title: `${venue.name}${venue.suburbName ? `, ${venue.suburbName}` : ""}`,
    description,
    alternates: {
      canonical: venuePath(venue.suburbName, venue.name),
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

  return (
    <VenuePageContent venue={venue} initialSelectedDay={initialSelectedDay} />
  );
}
