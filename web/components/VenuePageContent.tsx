import { WeeklyDealsSection } from "@/components/WeeklyDealsSection";
import { VenueMapCameraSeed } from "@/components/VenueMapCameraSeed";
import { googleMapsPlaceUrl } from "@/lib/search/google-maps";
import type { VenueDetailResult } from "@/lib/search/queries";
import { venuePath } from "@/lib/search/slugs";
import { Building2, CirclePlus, Link, MapPin } from "lucide-react";
import NextLink from "next/link";
import type { ReactNode } from "react";
import { SiFacebook, SiInstagram } from "react-icons/si";

type VenuePageContentProps = {
  venue: VenueDetailResult;
  initialSelectedDay?: number | null;
};

const linkClassName =
  "inline-flex items-center gap-1.5 rounded-full border border-border px-3 py-1.5 text-sm font-medium text-accent-soft transition-colors hover:border-accent hover:bg-accent-muted";

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

export function VenuePageContent({
  venue,
  initialSelectedDay,
}: VenuePageContentProps) {
  const mapsUrl = googleMapsPlaceUrl(venue.name, venue.googleMapId);
  const path = venuePath(venue.suburbName, venue.name);

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-6 py-10">
      <VenueMapCameraSeed listPath={path} lat={venue.lat} lng={venue.lng} />
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
            className="flex aspect-[21/9] w-full items-center justify-center rounded-xl border border-dashed border-border bg-surface-muted"
          >
            <Building2
              aria-hidden
              strokeWidth={1.5}
              className="h-14 w-14 text-muted"
            />
          </div>
        )}
        <h1 className="text-3xl font-bold text-foreground">
          {venue.name}
        </h1>
        <div className="flex flex-wrap gap-2">
          {venue.websiteUri ? (
            <VenueExternalLink
              href={venue.websiteUri}
              icon={
                <Link
                  aria-hidden
                  className="h-4 w-4 shrink-0"
                  strokeWidth={1.5}
                />
              }
            >
              Website
            </VenueExternalLink>
          ) : null}
          <VenueExternalLink
            href={mapsUrl}
            icon={
              <MapPin
                aria-hidden
                className="h-4 w-4 shrink-0"
                strokeWidth={1.5}
              />
            }
          >
            Map
          </VenueExternalLink>
          {venue.links?.instagram ? (
            <VenueExternalLink
              href={venue.links.instagram}
              icon={
                <SiInstagram aria-hidden className="h-4 w-4 shrink-0" />
              }
            >
              Instagram
            </VenueExternalLink>
          ) : null}
          {venue.links?.facebook ? (
            <VenueExternalLink
              href={venue.links.facebook}
              icon={<SiFacebook aria-hidden className="h-4 w-4 shrink-0" />}
            >
              Facebook
            </VenueExternalLink>
          ) : null}
        </div>
        {venue.blurb ? (
          <p className="whitespace-pre-line text-base leading-relaxed text-secondary">
            {venue.blurb}
          </p>
        ) : null}
      </header>

      <p
        role="note"
        className="rounded-lg border border-accent bg-accent-muted px-4 py-3 text-sm text-accent-soft"
      >
        Deals may be out of date. Please check with the venue when ordering.
      </p>

      <WeeklyDealsSection
        deals={venue.deals}
        initialSelectedDay={initialSelectedDay}
        showReportButton
      />

      <NextLink href={`${path}/new-deal`} className={linkClassName}>
        <CirclePlus
          aria-hidden
          className="h-4 w-4 shrink-0"
          strokeWidth={1.5}
        />
        Add a missing deal
      </NextLink>
    </div>
  );
}
