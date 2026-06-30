import { BackToSearchLink } from "@/components/BackToSearchLink";
import { WeeklyDealsSection } from "@/components/WeeklyDealsSection";
import { googleMapsPlaceUrl } from "@/lib/search/google-maps";
import type { VenueDetailResult } from "@/lib/search/queries";
import type { ReactNode } from "react";

type VenuePageContentProps = {
  venue: VenueDetailResult;
  initialSelectedDay?: number | null;
};

const linkClassName =
  "inline-flex items-center gap-1.5 rounded-full border border-zinc-300 px-3 py-1.5 text-sm font-medium text-amber-700 transition-colors hover:border-amber-500 hover:bg-amber-50 dark:border-zinc-600 dark:text-amber-400 dark:hover:border-amber-500 dark:hover:bg-amber-950/30";

function VenueExternalLink({
  href,
  children,
  icon,
}: {
  href: string;
  children: ReactNode;
  icon: ReactNode;
}) {
  return (
    <a href={href} target="_blank" rel="noreferrer" className={linkClassName}>
      {icon}
      {children}
    </a>
  );
}

function LinkIcon() {
  return (
    <svg
      aria-hidden="true"
      className="h-4 w-4 shrink-0"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth={1.5}
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M13.19 8.688a4.5 4.5 0 011.242 7.244l-4.5 4.5a4.5 4.5 0 01-6.364-6.364l1.757-1.757m13.35-.622l1.757-1.757a4.5 4.5 0 00-6.364-6.364l-4.5 4.5a4.5 4.5 0 001.242 7.244"
      />
    </svg>
  );
}

function MapPinIcon() {
  return (
    <svg
      aria-hidden="true"
      className="h-4 w-4 shrink-0"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth={1.5}
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z"
      />
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z"
      />
    </svg>
  );
}

function InstagramIcon() {
  return (
    <svg
      aria-hidden="true"
      className="h-4 w-4 shrink-0"
      fill="currentColor"
      viewBox="0 0 24 24"
    >
      <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zm0 10.162a3.999 3.999 0 110-7.998 3.999 3.999 0 010 7.998zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z" />
    </svg>
  );
}

function FacebookIcon() {
  return (
    <svg
      aria-hidden="true"
      className="h-4 w-4 shrink-0"
      fill="currentColor"
      viewBox="0 0 24 24"
    >
      <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" />
    </svg>
  );
}

export function VenuePageContent({
  venue,
  initialSelectedDay,
}: VenuePageContentProps) {
  const mapsUrl = googleMapsPlaceUrl(venue.name, venue.googleMapId);

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
        <div className="flex flex-wrap gap-2">
          {venue.websiteUri ? (
            <VenueExternalLink href={venue.websiteUri} icon={<LinkIcon />}>
              Website
            </VenueExternalLink>
          ) : null}
          <VenueExternalLink href={mapsUrl} icon={<MapPinIcon />}>
            Map
          </VenueExternalLink>
          {venue.links?.instagram ? (
            <VenueExternalLink
              href={venue.links.instagram}
              icon={<InstagramIcon />}
            >
              Instagram
            </VenueExternalLink>
          ) : null}
          {venue.links?.facebook ? (
            <VenueExternalLink
              href={venue.links.facebook}
              icon={<FacebookIcon />}
            >
              Facebook
            </VenueExternalLink>
          ) : null}
        </div>
      </header>

      <WeeklyDealsSection
        deals={venue.deals}
        initialSelectedDay={initialSelectedDay}
      />
    </div>
  );
}
