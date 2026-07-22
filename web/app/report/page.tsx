import { ReportPageContent } from "@/components/ReportPageContent";
import { auth } from "@/lib/auth";
import { getDealsByIds } from "@/lib/search/queries";
import { venuePath } from "@/lib/search/slugs";
import type { Metadata } from "next";
import { headers } from "next/headers";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Report a deal",
  description: "Report incorrect or outdated deal information.",
};

type ReportPageProps = {
  searchParams: Promise<{ dealId?: string }>;
};

export default async function ReportPage({ searchParams }: ReportPageProps) {
  const { dealId: dealIdParam } = await searchParams;
  const dealId =
    dealIdParam !== undefined && dealIdParam !== ""
      ? Number(dealIdParam)
      : NaN;

  if (!Number.isFinite(dealId) || !Number.isInteger(dealId) || dealId <= 0) {
    return (
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col gap-4 px-4 py-10 md:px-6 text-center">
        <h1 className="text-2xl font-bold text-foreground">
          Deal not found
        </h1>
        <p className="text-sm text-secondary">
          A valid deal is required to submit a report.
        </p>
        <Link
          href="/"
          className="text-sm font-medium text-accent-soft hover:text-foreground"
        >
          Back to search
        </Link>
      </div>
    );
  }

  const deals = await getDealsByIds([dealId]);
  const deal = deals[0];

  if (!deal) {
    return (
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col gap-4 px-4 py-10 md:px-6 text-center">
        <h1 className="text-2xl font-bold text-foreground">
          Deal not found
        </h1>
        <p className="text-sm text-secondary">
          This deal may have been removed or does not exist.
        </p>
        <Link
          href="/"
          className="text-sm font-medium text-accent-soft hover:text-foreground"
        >
          Back to search
        </Link>
      </div>
    );
  }

  const session = await auth.api.getSession({
    headers: await headers(),
  });

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col px-4 py-10 md:px-6">
      <ReportPageContent
        dealId={deal.id}
        dealTitle={deal.title || "Untitled deal"}
        venueName={deal.venue.name}
        venuePath={venuePath(deal.venue.suburbName, deal.venue.name)}
        isLoggedIn={Boolean(session)}
      />
    </div>
  );
}
