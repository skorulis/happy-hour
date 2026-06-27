import { BackToSearchLink } from "@/components/BackToSearchLink";
import { DealCard } from "@/components/DealCard";
import type { VenueDetailResult } from "@/lib/search/queries";
import { groupDealsByDay } from "@/lib/search/schedule";
import { dealAnchorId } from "@/lib/search/slugs";

type VenuePageContentProps = {
  venue: VenueDetailResult;
};

export function VenuePageContent({ venue }: VenuePageContentProps) {
  const mapsUrl = `https://www.google.com/maps/search/?api=1&query=${venue.lat},${venue.lng}`;
  const dealsByDay = groupDealsByDay(venue.deals);
  const anchoredDealIds = new Set<number>();

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-6 py-10">
      <div>
        <BackToSearchLink />
      </div>

      <header className="space-y-4">
        {venue.heroImage ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={venue.heroImage}
            alt={venue.name}
            className="aspect-[21/9] w-full rounded-xl object-cover"
          />
        ) : (
          <div
            aria-hidden
            className="flex aspect-[21/9] w-full items-center justify-center rounded-xl border border-dashed border-zinc-300 bg-zinc-100 dark:border-zinc-700 dark:bg-zinc-900"
          >
            <svg
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.5"
              className="h-14 w-14 text-zinc-400 dark:text-zinc-600"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M2.25 21h19.5M3.75 21V9.75m16.5 11.25V9.75M4.5 9.75 12 3.75l7.5 6M9 21v-4.5h6V21"
              />
            </svg>
          </div>
        )}
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
                  {deals.map((deal) => {
                    const anchorId = anchoredDealIds.has(deal.id)
                      ? undefined
                      : dealAnchorId(deal.id);
                    if (anchorId) {
                      anchoredDealIds.add(deal.id);
                    }

                    return (
                      <DealCard
                        key={`${dayOfWeek}-${deal.id}`}
                        id={anchorId}
                        deal={deal}
                        showVenue={false}
                        dayOfWeek={dayOfWeek}
                      />
                    );
                  })}
                </div>
              </div>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
