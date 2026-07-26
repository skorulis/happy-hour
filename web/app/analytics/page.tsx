import type { Metadata } from "next";
import { headers } from "next/headers";
import { RestrictedMessage } from "@/components/AdminPageContent";
import { AnalyticsDashboard } from "@/components/analytics/AnalyticsDashboard";
import { isAdmin } from "@/lib/admin";
import { getSearchesByDay } from "@/lib/analytics/queries";
import { auth } from "@/lib/auth";

export const metadata: Metadata = {
  title: "Analytics",
  description: "DuskRoute product analytics.",
};

export default async function AnalyticsPage() {
  const session = await auth.api.getSession({
    headers: await headers(),
  });

  if (!session || !isAdmin(session.user.email)) {
    return <RestrictedMessage />;
  }

  const searchesByDay = await getSearchesByDay();

  return (
    <AnalyticsDashboard
      backHref="/admin"
      backLabel="Back to admin"
      heading="Analytics"
      intro="How people are searching for happy-hour deals."
      searchDayDescription="Day filter on suburb and nearby searches, including any day."
      searchesByDay={searchesByDay}
    />
  );
}
