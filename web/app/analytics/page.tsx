import type { Metadata } from "next";
import Link from "next/link";
import { headers } from "next/headers";
import { RestrictedMessage } from "@/components/AdminPageContent";
import { SearchDayPieChart } from "@/components/analytics/SearchDayPieChart";
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
    <div className="mx-auto flex w-full max-w-5xl flex-1 flex-col gap-10 px-4 py-10 md:px-6">
      <header className="space-y-3">
        <Link
          href="/admin"
          className="text-sm font-medium text-accent-soft transition-colors hover:text-foreground"
        >
          Back to admin
        </Link>
        <div className="space-y-2">
          <h1 className="text-3xl font-bold text-foreground">Analytics</h1>
          <p className="max-w-2xl text-sm text-secondary">
            How people are searching for happy-hour deals.
          </p>
        </div>
      </header>

      <section aria-labelledby="search-day-heading" className="space-y-6">
        <div className="space-y-2">
          <h2
            id="search-day-heading"
            className="text-xl font-semibold text-foreground"
          >
            Search day of week
          </h2>
          <p className="text-sm text-secondary">
            Searches where a single day was selected.
          </p>
        </div>
        <SearchDayPieChart data={searchesByDay} />
      </section>
    </div>
  );
}
