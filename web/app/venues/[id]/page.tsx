import { notFound, redirect } from "next/navigation";
import { getVenueDetail } from "@/lib/search/queries";
import { venuePath } from "@/lib/search/slugs";

type LegacyVenuePageProps = {
  params: Promise<{ id: string }>;
};

export default async function LegacyVenuePage({ params }: LegacyVenuePageProps) {
  const { id } = await params;
  const venueId = Number(id);

  if (!Number.isFinite(venueId)) {
    notFound();
  }

  const venue = await getVenueDetail(venueId);

  if (!venue) {
    notFound();
  }

  redirect(venuePath(venue.suburbName, venue.name));
}
