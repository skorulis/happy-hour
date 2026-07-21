import type { Metadata } from "next";
import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { ProfileContributionsPageContent } from "@/components/ProfileContributionsPageContent";
import { auth } from "@/lib/auth";
import { getContributionsForUser } from "@/lib/deals/queries";

export const metadata: Metadata = {
  title: "Contributions",
  description: "Deals you have submitted.",
};

export default async function ProfileContributionsPage() {
  const session = await auth.api.getSession({
    headers: await headers(),
  });

  if (!session) {
    redirect("/login?callbackUrl=/profile/contributions");
  }

  const contributions = await getContributionsForUser(session.user.id);
  const pendingContributions = contributions.filter(
    (contribution) => contribution.status === "new",
  );
  const historicalContributions = contributions.filter(
    (contribution) =>
      contribution.status === "approved" || contribution.status === "rejected",
  );

  return (
    <ProfileContributionsPageContent
      pendingContributions={pendingContributions}
      historicalContributions={historicalContributions}
    />
  );
}
