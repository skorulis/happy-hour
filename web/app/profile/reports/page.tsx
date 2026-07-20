import type { Metadata } from "next";
import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { ProfileReportsPageContent } from "@/components/ProfileReportsPageContent";
import { auth } from "@/lib/auth";
import { getReportsForUser } from "@/lib/reports/queries";

export const metadata: Metadata = {
  title: "Reports",
  description: "Deal reports you have submitted.",
};

export default async function ProfileReportsPage() {
  const session = await auth.api.getSession({
    headers: await headers(),
  });

  if (!session) {
    redirect("/login?callbackUrl=/profile/reports");
  }

  const reports = await getReportsForUser(session.user.id);
  const openReports = reports.filter((report) => report.status === "new");
  const historicalReports = reports.filter(
    (report) => report.status === "approved" || report.status === "rejected",
  );

  return (
    <ProfileReportsPageContent
      openReports={openReports}
      historicalReports={historicalReports}
    />
  );
}
