import Link from "next/link";
import { formatScheduleSummary } from "@/lib/search/schedule";
import type { DealSearchResult } from "@/lib/search/queries";

type DealCardProps = {
  deal: DealSearchResult;
  showVenue?: boolean;
};

export function DealCard({ deal, showVenue = true }: DealCardProps) {
  return (
    <article className="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm dark:border-zinc-800 dark:bg-zinc-950">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div className="space-y-2">
          <h3 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
            {deal.title || "Untitled deal"}
          </h3>
          {showVenue ? (
            <p className="text-sm text-zinc-600 dark:text-zinc-400">
              <Link
                href={`/venues/${deal.venue.id}`}
                className="font-medium text-amber-700 hover:underline dark:text-amber-400"
              >
                {deal.venue.name}
              </Link>
            </p>
          ) : null}
          <p className="text-sm font-medium text-zinc-700 dark:text-zinc-300">
            {formatScheduleSummary(deal.schedules)}
          </p>
          {deal.details ? (
            <p className="whitespace-pre-wrap text-sm text-zinc-700 dark:text-zinc-300">
              {deal.details}
            </p>
          ) : null}
          {deal.conditions ? (
            <p className="whitespace-pre-wrap text-sm text-zinc-500 dark:text-zinc-400">
              {deal.conditions}
            </p>
          ) : null}
        </div>
        {deal.imageUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={deal.imageUrl}
            alt={deal.title || "Deal image"}
            className="h-28 w-28 rounded-lg object-cover"
          />
        ) : null}
      </div>
      {deal.sourceUrl ? (
        <a
          href={deal.sourceUrl}
          target="_blank"
          rel="noreferrer"
          className="mt-4 inline-block text-sm text-amber-700 hover:underline dark:text-amber-400"
        >
          View source
        </a>
      ) : null}
    </article>
  );
}
