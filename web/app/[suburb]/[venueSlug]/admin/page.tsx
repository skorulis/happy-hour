import type { Metadata } from "next";
import { headers } from "next/headers";
import { notFound } from "next/navigation";
import { RestrictedMessage } from "@/components/AdminPageContent";
import { VenueAdminPageContent } from "@/components/VenueAdminPageContent";
import { canManageVenue } from "@/lib/admin";
import { auth } from "@/lib/auth";
import { getDealReportsForVenue } from "@/lib/reports/queries";
import { getVenueDetailBySlug } from "@/lib/search/queries";
import { listVenueOwners } from "@/lib/venue-ownership/queries";

type VenueAdminPageProps = {
  params: Promise<{ suburb: string; venueSlug: string }>;
};

export async function generateMetadata({
  params,
}: VenueAdminPageProps): Promise<Metadata> {
  const { suburb, venueSlug } = await params;
  const venue = await getVenueDetailBySlug(suburb, venueSlug);

  if (!venue) {
    return { robots: { index: false, follow: false } };
  }

  return {
    title: `Admin · ${venue.name}`,
    robots: { index: false, follow: false },
  };
}

export default async function VenueAdminPage({ params }: VenueAdminPageProps) {
  const { suburb, venueSlug } = await params;
  const venue = await getVenueDetailBySlug(suburb, venueSlug);

  if (!venue) {
    notFound();
  }

  const session = await auth.api.getSession({
    headers: await headers(),
  });

  if (!session || !(await canManageVenue(session.user, venue.id))) {
    return <RestrictedMessage />;
  }

  const [owners, reports] = await Promise.all([
    listVenueOwners(venue.id),
    getDealReportsForVenue(venue.id),
  ]);

  return (
    <VenueAdminPageContent
      venueName={venue.name}
      venueId={venue.id}
      reports={reports}
      owners={owners}
      currentUserId={session.user.id}
    />
  );
}
