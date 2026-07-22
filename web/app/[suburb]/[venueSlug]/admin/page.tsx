import type { Metadata } from "next";
import { headers } from "next/headers";
import { notFound } from "next/navigation";
import { RestrictedMessage } from "@/components/AdminPageContent";
import { canManageVenue } from "@/lib/admin";
import { auth } from "@/lib/auth";
import { getVenueDetailBySlug } from "@/lib/search/queries";

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

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-4 px-6 py-10">
      <h1 className="text-3xl font-bold text-foreground">
        Admin · {venue.name}
      </h1>
      <p className="text-base leading-relaxed text-secondary">
        Venue admin tools will live here. This page is a placeholder for now —
        manage deals, hours, and venue details from this dashboard in a future
        update.
      </p>
    </div>
  );
}
