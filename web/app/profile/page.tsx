import type { Metadata } from "next";
import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { ProfilePageContent } from "@/components/ProfilePageContent";
import { isAdmin } from "@/lib/admin";
import { auth } from "@/lib/auth";

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

  return (
    <ProfilePageContent
      name={session.user.name}
      email={session.user.email}
      isAdmin={isAdmin(session.user.email)}
    />
  );
}
