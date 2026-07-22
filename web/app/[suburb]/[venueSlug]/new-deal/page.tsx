import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { NewDealPageContent } from "@/components/NewDealPageContent";
import { getVenueDetailBySlug } from "@/lib/search/queries";
import { venuePath } from "@/lib/search/slugs";

type NewDealPageProps = {
  params: Promise<{ suburb: string; venueSlug: string }>;
};

export async function generateMetadata({
  params,
}: NewDealPageProps): Promise<Metadata> {
  const { suburb, venueSlug } = await params;
  const venue = await getVenueDetailBySlug(suburb, venueSlug);

  if (!venue) {
    return {};
  }

  const title = `Add a new deal to ${venue.name}`;

  return {
    title,
  };
}

export default async function NewDealPage({ params }: NewDealPageProps) {
  const { suburb, venueSlug } = await params;
  const venue = await getVenueDetailBySlug(suburb, venueSlug);

  if (!venue) {
    notFound();
  }

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-4 py-10 md:px-6">
      <NewDealPageContent
        venueId={venue.id}
        venueName={venue.name}
        venuePath={venuePath(venue.suburbName, venue.name)}
      />
    </div>
  );
}
