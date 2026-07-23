"use client";

import Link from "next/link";
import { Building2, MapPin, X } from "lucide-react";
import { useState } from "react";
import Lightbox from "yet-another-react-lightbox";
import "yet-another-react-lightbox/styles.css";
import { DealProductIcon } from "@/components/DealProductIcon";
import type { VenueGroupedDeals } from "@/components/VenueSearchCard";
import { track } from "@/lib/analytics/client";
import { isCreativeImageUrl } from "@/lib/search/creative-url";
import {
  formatDealDayBadge,
  formatDealTimeBadge,
  sortDealsActiveFirst,
} from "@/lib/search/schedule";
import { slugify, venuePath } from "@/lib/search/slugs";
import { appendDayToPath } from "@/lib/search/day-path";
import { venueHeroThumbUrl } from "@/lib/search/venue-hero-url";

type VenueMapPopupProps = {
  group: VenueGroupedDeals;
  searchDays?: number[];
  now: Date;
  onClose: () => void;
};

function specialsListedLabel(count: number): string {
  return count === 1 ? "1 special listed" : `${count} specials listed`;
}

function DealThumbnail({
  deal,
}: {
  deal: VenueGroupedDeals["deals"][number];
}) {
  const imageUrl = isCreativeImageUrl(deal.imageUrl) ? deal.imageUrl : null;
  const [lightboxOpen, setLightboxOpen] = useState(false);

  if (imageUrl) {
    return (
      <>
        <button
          type="button"
          onClick={() => setLightboxOpen(true)}
          className="h-14 w-14 shrink-0 cursor-zoom-in"
          aria-label="View full-size deal image"
        >
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={imageUrl}
            alt={deal.title || "Deal image"}
            className="h-14 w-14 rounded-lg object-cover"
          />
        </button>
        <Lightbox
          open={lightboxOpen}
          close={() => setLightboxOpen(false)}
          slides={[
            { src: imageUrl, alt: deal.title || "Deal image" },
          ]}
          carousel={{ finite: true }}
          render={{ buttonPrev: () => null, buttonNext: () => null }}
        />
      </>
    );
  }

  return (
    <span className="inline-flex h-14 w-14 shrink-0 items-center justify-center rounded-lg bg-accent-muted">
      <DealProductIcon deal={deal} size={20} variant="plain" />
    </span>
  );
}

export function VenueMapPopup({
  group,
  searchDays = [],
  now,
  onClose,
}: VenueMapPopupProps) {
  const previewDeals = sortDealsActiveFirst(group.deals, now).slice(0, 2);
  const venueHref = appendDayToPath(
    venuePath(group.venue.suburbName, group.venue.name),
    searchDays,
  );
  const imageUrl =
    venueHeroThumbUrl(group.venue.heroImage) ??
    group.deals.find((deal) => isCreativeImageUrl(deal.imageUrl))?.imageUrl ??
    null;

  return (
    <div className="relative box-border flex w-full max-w-full overflow-hidden rounded-xl bg-surface-elevated text-foreground">
      <button
        type="button"
        onClick={onClose}
        className="absolute top-2 right-2 z-10 flex h-7 w-7 items-center justify-center rounded-full text-muted transition-colors hover:bg-surface-muted hover:text-secondary"
        aria-label="Close"
      >
        <X aria-hidden className="h-4 w-4" strokeWidth={2} />
      </button>

      <div className="flex w-[38%] max-w-44 shrink-0 flex-col border-r border-border-subtle p-3">
        {imageUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={imageUrl}
            alt=""
            className="mb-3 aspect-[4/3] w-full rounded-lg object-cover"
          />
        ) : (
          <div
            aria-hidden
            className="mb-3 flex aspect-[4/3] w-full items-center justify-center rounded-lg bg-surface-muted"
          >
            <Building2
              className="h-8 w-8 text-muted"
              strokeWidth={1.5}
            />
          </div>
        )}

        <p className="text-base font-bold leading-tight">{group.venue.name}</p>

        {group.venue.formattedAddress ? (
          <p className="mt-2 inline-flex items-start gap-1.5 text-xs leading-snug text-secondary">
            <MapPin
              aria-hidden
              className="mt-0.5 h-3.5 w-3.5 shrink-0 text-accent-soft"
              strokeWidth={1.75}
            />
            <span>{group.venue.formattedAddress}</span>
          </p>
        ) : null}

        <Link
          href={venueHref}
          className="mt-auto block rounded-lg bg-gradient-to-b from-accent to-accent-hover px-3 py-2 text-center text-sm font-semibold text-accent-fg"
          onClick={() => {
            track("venue_opened", {
              venue_id: group.venue.id,
              source: "map",
              suburb_slug: group.venue.suburbName
                ? slugify(group.venue.suburbName)
                : null,
            });
          }}
        >
          View Listing
        </Link>
      </div>

      <div className="min-w-0 flex-1 p-3 pr-8">
        <p className="text-sm text-secondary">
          {specialsListedLabel(group.deals.length)}
        </p>

        {previewDeals.length > 0 ? (
          <ul className="mt-3 space-y-4">
            {previewDeals.map((deal) => {
              const timeBadge = formatDealTimeBadge(deal.schedules);
              const description =
                deal.details?.trim() || deal.conditions?.trim();

              return (
                <li key={deal.id} className="flex gap-2.5">
                  <DealThumbnail deal={deal} />
                  <div className="min-w-0 space-y-1">
                    <p className="text-sm font-semibold leading-tight">
                      {deal.title || "Untitled deal"}
                    </p>
                    {description ? (
                      <p className="line-clamp-3 text-xs leading-relaxed text-secondary">
                        {description}
                      </p>
                    ) : null}
                    <p className="text-xs text-muted">
                      {formatDealDayBadge(deal.schedules)}
                      {timeBadge && timeBadge !== "—" ? ` · ${timeBadge}` : ""}
                    </p>
                  </div>
                </li>
              );
            })}
            {group.deals.length > previewDeals.length ? (
              <li className="text-xs text-muted">
                +{group.deals.length - previewDeals.length} more
              </li>
            ) : null}
          </ul>
        ) : null}
      </div>
    </div>
  );
}
