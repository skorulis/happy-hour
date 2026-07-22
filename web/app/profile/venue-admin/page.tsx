import type { Metadata } from "next";
import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { ProfileVenueAdminPageContent } from "@/components/ProfileVenueAdminPageContent";
import { auth } from "@/lib/auth";
import { listVenuesForOwner } from "@/lib/venue-ownership/queries";

export const metadata: Metadata = {
  title: "Venue admin",
  description: "Venues you can manage as an admin.",
};

export default async function ProfileVenueAdminPage() {
  const session = await auth.api.getSession({
    headers: await headers(),
  });

  if (!session) {
    redirect("/login?callbackUrl=/profile/venue-admin");
  }

  const venues = await listVenuesForOwner(session.user.id);

  return <ProfileVenueAdminPageContent venues={venues} />;
}
