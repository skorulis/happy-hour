import { ReportPageContent } from "@/components/ReportPageContent";
import { getDealsByIds } from "@/lib/search/queries";
import { venuePath } from "@/lib/search/slugs";
import type { Metadata } from "next";
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
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col gap-4 px-6 py-10 text-center">
        <h1 className="text-2xl font-bold text-zinc-900 dark:text-zinc-50">
          Deal not found
        </h1>
        <p className="text-sm text-zinc-600 dark:text-zinc-400">
          A valid deal is required to submit a report.
        </p>
        <Link
          href="/"
          className="text-sm font-medium text-amber-700 hover:text-amber-800 dark:text-amber-400 dark:hover:text-amber-300"
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
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col gap-4 px-6 py-10 text-center">
        <h1 className="text-2xl font-bold text-zinc-900 dark:text-zinc-50">
          Deal not found
        </h1>
        <p className="text-sm text-zinc-600 dark:text-zinc-400">
          This deal may have been removed or does not exist.
        </p>
        <Link
          href="/"
          className="text-sm font-medium text-amber-700 hover:text-amber-800 dark:text-amber-400 dark:hover:text-amber-300"
        >
          Back to search
        </Link>
      </div>
    );
  }

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col px-6 py-10">
      <ReportPageContent
        dealId={deal.id}
        dealTitle={deal.title || "Untitled deal"}
        venueName={deal.venue.name}
        venuePath={venuePath(deal.venue.suburbName, deal.venue.name)}
      />
    </div>
  );
}
