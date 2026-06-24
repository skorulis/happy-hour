import Link from "next/link";
import { DealCard } from "@/components/DealCard";
import type { VenueDetailResult } from "@/lib/search/queries";
import { groupDealsByDay } from "@/lib/search/schedule";

type VenuePageContentProps = {
  venue: VenueDetailResult;
};

export function VenuePageContent({ venue }: VenuePageContentProps) {
  const mapsUrl = `https://www.google.com/maps/search/?api=1&query=${venue.lat},${venue.lng}`;
  const dealsByDay = groupDealsByDay(venue.deals);

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-6 py-10">
      <div>
        <Link
          href="/"
          className="text-sm font-medium text-amber-700 hover:underline dark:text-amber-400"
        >
          ← Back to search
        </Link>
      </div>

      <header className="space-y-3">
        <h1 className="text-3xl font-bold text-zinc-900 dark:text-zinc-50">
          {venue.name}
        </h1>
        <div className="flex flex-wrap gap-4 text-sm text-zinc-600 dark:text-zinc-400">
          {venue.websiteUri ? (
            <a
              href={venue.websiteUri}
              target="_blank"
              rel="noreferrer"
              className="text-amber-700 hover:underline dark:text-amber-400"
            >
              Website
            </a>
          ) : null}
          <a
            href={mapsUrl}
            target="_blank"
            rel="noreferrer"
            className="text-amber-700 hover:underline dark:text-amber-400"
          >
            Map
          </a>
          {venue.links?.whatsOn ? (
            <a
              href={venue.links.whatsOn}
              target="_blank"
              rel="noreferrer"
              className="text-amber-700 hover:underline dark:text-amber-400"
            >
              What&apos;s on
            </a>
          ) : null}
          {venue.links?.instagram ? (
            <a
              href={venue.links.instagram}
              target="_blank"
              rel="noreferrer"
              className="text-amber-700 hover:underline dark:text-amber-400"
            >
              Instagram
            </a>
          ) : null}
          {venue.links?.facebook ? (
            <a
              href={venue.links.facebook}
              target="_blank"
              rel="noreferrer"
              className="text-amber-700 hover:underline dark:text-amber-400"
            >
              Facebook
            </a>
          ) : null}
        </div>
      </header>

      <section className="space-y-4">
        <h2 className="text-xl font-semibold text-zinc-900 dark:text-zinc-50">
          Deals ({venue.deals.length})
        </h2>
        {dealsByDay.length === 0 ? (
          <p className="rounded-xl border border-dashed border-zinc-300 px-4 py-8 text-center text-sm text-zinc-500 dark:border-zinc-700 dark:text-zinc-400">
            No approved deals have been synced for this venue yet.
          </p>
        ) : (
          <div className="space-y-8">
            {dealsByDay.map(({ dayOfWeek, dayLabel, deals }) => (
              <div key={dayOfWeek} className="space-y-4">
                <h3 className="text-2xl font-bold text-zinc-700 dark:text-zinc-300">
                  {dayLabel}
                </h3>
                <div className="grid gap-4">
                  {deals.map((deal) => (
                    <DealCard
                      key={`${dayOfWeek}-${deal.id}`}
                      deal={deal}
                      showVenue={false}
                      dayOfWeek={dayOfWeek}
                    />
                  ))}
                </div>
              </div>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
