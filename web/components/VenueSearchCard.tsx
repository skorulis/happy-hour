import Link from "next/link";
import {
  formatDealDayBadge,
  formatDealTimeBadge,
} from "@/lib/search/schedule";
import type { DealSearchResult } from "@/lib/search/queries";
import { dealPath, venuePath } from "@/lib/search/slugs";

export type VenueGroupedDeals = {
  venue: DealSearchResult["venue"];
  deals: DealSearchResult[];
};

export function groupDealsByVenue(deals: DealSearchResult[]): VenueGroupedDeals[] {
  const groups = new Map<number, VenueGroupedDeals>();

  for (const deal of deals) {
    const existing = groups.get(deal.venue.id);
    if (existing) {
      existing.deals.push(deal);
    } else {
      groups.set(deal.venue.id, {
        venue: deal.venue,
        deals: [deal],
      });
    }
  }

  return Array.from(groups.values());
}

type VenueSearchCardProps = {
  group: VenueGroupedDeals;
};

export function VenueSearchCard({ group }: VenueSearchCardProps) {
  const imageUrl =
    group.venue.heroImage ??
    group.deals.find((deal) => deal.imageUrl)?.imageUrl ??
    null;

  return (
    <article className="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm dark:border-zinc-800 dark:bg-zinc-950">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div className="min-w-0 flex-1 space-y-4">
          <ul className="space-y-2">
            {group.deals.map((deal) => {
              const timeBadge = formatDealTimeBadge(deal.schedules);

              return (
                <li key={deal.id}>
                  <Link
                    href={dealPath(
                      group.venue.suburbName,
                      group.venue.name,
                      deal.id,
                    )}
                    className="-mx-2 flex flex-wrap items-center gap-2 rounded-md px-2 py-1 text-sm hover:bg-zinc-50 hover:text-amber-700 dark:hover:bg-zinc-900 dark:hover:text-amber-400"
                  >
                    <span className="font-semibold text-zinc-900 hover:underline dark:text-zinc-50">
                      {deal.title || "Untitled deal"}
                    </span>
                    <span className="inline-flex items-center rounded-md bg-zinc-900 px-2 py-0.5 text-xs font-medium text-white dark:bg-zinc-100 dark:text-zinc-900">
                      {formatDealDayBadge(deal.schedules)}
                    </span>
                    {timeBadge && timeBadge !== "—" ? (
                      <span className="inline-flex items-center rounded-md border border-zinc-300 px-2 py-0.5 text-xs font-medium text-zinc-500 dark:border-zinc-600 dark:text-zinc-400">
                        {timeBadge}
                      </span>
                    ) : null}
                  </Link>
                </li>
              );
            })}
          </ul>

          <p className="text-sm text-zinc-500 dark:text-zinc-400">
            <Link
              href={venuePath(group.venue.suburbName, group.venue.name)}
              className="hover:text-amber-700 hover:underline dark:hover:text-amber-400"
            >
              {group.venue.name}
            </Link>
            {group.venue.formattedAddress ? (
              <span> {group.venue.formattedAddress}</span>
            ) : null}
          </p>
        </div>

        {imageUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={imageUrl}
            alt={group.venue.name}
            className="h-36 w-full shrink-0 rounded-lg object-cover sm:h-40 sm:w-44"
          />
        ) : null}
      </div>
    </article>
  );
}
