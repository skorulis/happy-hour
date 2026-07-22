import type { Metadata } from "next";
import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { ProfilePageContent } from "@/components/ProfilePageContent";
import { isAdmin } from "@/lib/admin";
import { auth } from "@/lib/auth";
import { userOwnsAnyVenue } from "@/lib/venue-ownership/queries";

export const metadata: Metadata = {
  title: "Profile",
  description: "Your DuskRoute account.",
};

export default async function ProfilePage() {
  const session = await auth.api.getSession({
    headers: await headers(),
  });

  if (!session) {
    redirect("/login?callbackUrl=/profile");
  }

  const hasVenueAdmin = await userOwnsAnyVenue(session.user.id);

  return (
    <ProfilePageContent
      name={session.user.name}
      email={session.user.email}
      emailVerified={session.user.emailVerified}
      isAdmin={isAdmin(session.user.email)}
      hasVenueAdmin={hasVenueAdmin}
    />
  );
}
