import type { Metadata } from "next";
import { headers } from "next/headers";
import { notFound } from "next/navigation";
import { RestrictedMessage } from "@/components/AdminPageContent";
import { AnalyticsDashboard } from "@/components/analytics/AnalyticsDashboard";
import { isAdmin } from "@/lib/admin";
import { getSearchesByDay } from "@/lib/analytics/queries";
import { auth } from "@/lib/auth";
import { findSuburbByWhereSlug } from "@/lib/search/queries";

type SuburbAnalyticsPageProps = {
  params: Promise<{ suburb: string }>;
};

export const metadata: Metadata = {
  title: "Suburb analytics",
  description: "DuskRoute product analytics for a single suburb.",
};

export default async function SuburbAnalyticsPage({
  params,
}: SuburbAnalyticsPageProps) {
  const session = await auth.api.getSession({
    headers: await headers(),
  });

  if (!session || !isAdmin(session.user.email)) {
    return <RestrictedMessage />;
  }

  const { suburb: whereSlug } = await params;
  const suburb = await findSuburbByWhereSlug(whereSlug);
  if (!suburb) {
    notFound();
  }

  const searchesByDay = await getSearchesByDay({ suburbId: suburb.id });

  return (
    <AnalyticsDashboard
      backHref="/analytics"
      backLabel="Back to analytics"
      heading={`Analytics for ${suburb.name}`}
      intro={`How people are searching for happy-hour deals in ${suburb.name}.`}
      searchDayDescription={`Day filter on suburb searches for ${suburb.name}, including any day.`}
      searchesByDay={searchesByDay}
    />
  );
}
