"use client";

import Link from "next/link";
import { useState } from "react";
import Lightbox from "yet-another-react-lightbox";
import "yet-another-react-lightbox/styles.css";
import { DealProductIcon } from "@/components/DealProductIcon";
import { DealScheduleLine } from "@/components/DealScheduleLine";
import { FavoriteDealButton } from "@/components/FavoriteDealButton";
import { FlagDealButton } from "@/components/FlagDealButton";
import { MarkdownText } from "@/components/MarkdownText";
import { isCreativeImageUrl } from "@/lib/search/creative-url";
import type { DealSearchResult } from "@/lib/search/queries";
import {
  formatDealDateRange,
  formatDealScheduleLine,
  formatScheduleSummary,
  isDealActiveNow,
  schedulesForDay,
} from "@/lib/search/schedule";
import { venuePath } from "@/lib/search/slugs";

type DealCardProps = {
  deal: DealSearchResult;
  showVenue?: boolean;
  dayOfWeek?: number;
  id?: string;
  isFavorited?: boolean;
  onToggleFavorite?: () => void;
  showReportButton?: boolean;
};

export function DealCard({
  deal,
  showVenue = true,
  dayOfWeek,
  id,
  isFavorited,
  onToggleFavorite,
  showReportButton = false,
}: DealCardProps) {
  const daySchedules =
    dayOfWeek !== undefined
      ? schedulesForDay(deal.schedules, dayOfWeek)
      : deal.schedules;
  const datePart = formatDealDateRange(deal.startDate, deal.endDate);
  const scheduleLine =
    dayOfWeek !== undefined
      ? formatDealScheduleLine(daySchedules, deal.startDate, deal.endDate)
      : (() => {
          const schedulePart =
            deal.schedules.length > 0
              ? formatScheduleSummary(deal.schedules)
              : null;
          const parts = [datePart, schedulePart].filter(
            (part): part is string => Boolean(part),
          );
          return parts.length > 0 ? parts.join(" · ") : "Schedule not listed";
        })();
  const activeNow = isDealActiveNow(daySchedules);
  const creativeImageUrl = isCreativeImageUrl(deal.imageUrl)
    ? deal.imageUrl
    : null;
  const [lightboxOpen, setLightboxOpen] = useState(false);
  const showFooterActions =
    Boolean(deal.sourceUrl) || showReportButton || Boolean(onToggleFavorite);

  return (
    <article
      id={id}
      className={`rounded-xl border border-border-subtle bg-surface/90 p-5 shadow-card transition-shadow hover:shadow-card-hover ${
        activeNow ? "border-l-2 border-l-accent pl-[calc(1.25rem-2px)]" : ""
      }`}
    >
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start">
        <div className="min-w-0 flex-1 space-y-2">
          <div className="space-y-2">
            <h3 className="text-lg font-semibold text-foreground">
              {deal.title || "Untitled deal"}
            </h3>
            <DealScheduleLine text={scheduleLine} />
          </div>
          {showVenue ? (
            <p className="text-sm text-secondary">
              <Link
                href={venuePath(deal.venue.suburbName, deal.venue.name)}
                className="font-medium text-accent-soft hover:underline"
              >
                {deal.venue.name}
              </Link>
            </p>
          ) : null}
          {deal.details ? (
            <MarkdownText className="text-sm text-secondary">
              {deal.details}
            </MarkdownText>
          ) : null}
          {deal.conditions ? (
            <MarkdownText className="text-sm text-muted">
              {deal.conditions}
            </MarkdownText>
          ) : null}
        </div>

        {creativeImageUrl ? (
          <>
            <button
              type="button"
              onClick={() => setLightboxOpen(true)}
              className="shrink-0 cursor-zoom-in self-start"
              aria-label="View full-size deal image"
            >
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={creativeImageUrl}
                alt={deal.title || "Deal image"}
                className="max-h-[120px] max-w-[200px] rounded-lg object-contain"
              />
            </button>
            <Lightbox
              open={lightboxOpen}
              close={() => setLightboxOpen(false)}
              slides={[{ src: creativeImageUrl, alt: deal.title || "Deal image" }]}
              carousel={{ finite: true }}
              render={{ buttonPrev: () => null, buttonNext: () => null }}
            />
          </>
        ) : (
          <span className="inline-flex h-14 w-14 shrink-0 items-center justify-center self-start rounded-lg bg-accent-muted">
            <DealProductIcon deal={deal} size={20} />
          </span>
        )}
      </div>
      {showFooterActions ? (
        <div
          className={`mt-4 flex items-center gap-2 ${deal.sourceUrl ? "justify-between" : "justify-end"}`}
        >
          {deal.sourceUrl ? (
            <a
              href={deal.sourceUrl}
              target="_blank"
              rel="noopener nofollow"
              className="inline-flex items-center rounded-lg bg-accent px-4 py-2 text-sm font-semibold text-accent-fg transition-colors hover:bg-accent-hover"
            >
              More info
            </a>
          ) : null}
          {onToggleFavorite || showReportButton ? (
            <div className="flex items-center gap-2">
              {onToggleFavorite ? (
                <FavoriteDealButton
                  isFavorited={isFavorited ?? false}
                  onToggle={onToggleFavorite}
                />
              ) : null}
              {showReportButton ? <FlagDealButton dealId={deal.id} /> : null}
            </div>
          ) : null}
        </div>
      ) : null}
      {deal.hasOpenReport ? (
        <p
          role="note"
          className="mt-4 rounded-lg border border-danger/30 bg-danger-muted px-3 py-2 text-xs text-danger"
        >
          This deal has been flagged as inaccurate
        </p>
      ) : null}
    </article>
  );
}
