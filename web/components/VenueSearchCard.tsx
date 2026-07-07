import Link from "next/link";
import { MapPin } from "lucide-react";
import { DealProductIcon } from "@/components/DealProductIcon";
import { DealScheduleLine } from "@/components/DealScheduleLine";
import { formatDistanceKm } from "@/lib/search/distance";
import type { DealSearchResult } from "@/lib/search/queries";
import { formatDealScheduleLine } from "@/lib/search/schedule";
import { venuePath } from "@/lib/search/slugs";
import { appendDaysParam } from "@/lib/search/url";

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
  searchDays?: number[];
};

export function VenueSearchCard({ group, searchDays = [] }: VenueSearchCardProps) {
  const venueHref = appendDaysParam(
    venuePath(group.venue.suburbName, group.venue.name),
    searchDays,
  );
  const imageUrl =
    group.venue.heroImage ??
    group.deals.find((deal) => deal.imageUrl)?.imageUrl ??
    null;

  return (
    <Link
      href={venueHref}
      className="block rounded-xl border border-zinc-100 bg-white p-5 shadow-sm transition-shadow hover:shadow-md dark:border-zinc-800 dark:bg-zinc-950"
    >
      <div className="flex gap-3">
        {imageUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={imageUrl}
            alt=""
            className="h-14 w-14 shrink-0 rounded-lg object-cover"
          />
        ) : null}

        <div className="min-w-0 flex-1">
          <div className="flex items-start justify-between gap-3">
            <div className="min-w-0">
              <p className="text-base font-semibold text-zinc-900 dark:text-zinc-50">
                {group.venue.name}
              </p>
              {group.venue.formattedAddress ? (
                <p className="mt-0.5 text-sm text-zinc-500 dark:text-zinc-400">
                  {group.venue.formattedAddress}
                </p>
              ) : null}
            </div>

            {group.venue.distanceKm !== undefined ? (
              <span className="inline-flex shrink-0 items-center gap-1 text-xs font-medium text-zinc-500 dark:text-zinc-400">
                <MapPin aria-hidden className="h-3.5 w-3.5" strokeWidth={1.75} />
                {formatDistanceKm(group.venue.distanceKm)}
              </span>
            ) : null}
          </div>
        </div>
      </div>

      <ul className="mt-4 space-y-3">
        {group.deals.map((deal) => {
          const scheduleLine = formatDealScheduleLine(
            deal.schedules,
            deal.startDate,
            deal.endDate,
          );

          return (
            <li
              key={deal.id}
              className="flex items-start gap-3"
            >
              <DealProductIcon deal={deal} />
              <div className="flex min-w-0 flex-1 flex-col gap-1 sm:flex-row sm:items-start sm:justify-between sm:gap-4">
                <span className="font-medium text-zinc-900 dark:text-zinc-50">
                  {deal.title || "Untitled deal"}
                </span>
                <DealScheduleLine
                  text={scheduleLine}
                  className="sm:text-right"
                />
              </div>
            </li>
          );
        })}
      </ul>
    </Link>
  );
}
