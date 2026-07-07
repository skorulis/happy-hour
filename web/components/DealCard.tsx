"use client";

import Link from "next/link";
import { useState } from "react";
import Lightbox from "yet-another-react-lightbox";
import "yet-another-react-lightbox/styles.css";
import { FavoriteDealButton } from "@/components/FavoriteDealButton";
import { FlagDealButton } from "@/components/FlagDealButton";
import { MarkdownText } from "@/components/MarkdownText";
import { isCreativeImageUrl } from "@/lib/search/creative-url";
import type { DealSearchResult } from "@/lib/search/queries";
import {
  formatDealDateRange,
  formatDealTimeBadge,
  formatScheduleSummary,
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
  const timeBadge =
    dayOfWeek !== undefined ? formatDealTimeBadge(daySchedules) : null;
  const dateBadge = formatDealDateRange(deal.startDate, deal.endDate);
  const creativeImageUrl = isCreativeImageUrl(deal.imageUrl)
    ? deal.imageUrl
    : null;
  const [lightboxOpen, setLightboxOpen] = useState(false);

  return (
    <article
      id={id}
      className="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm dark:border-zinc-800 dark:bg-zinc-950"
    >
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start">
        {creativeImageUrl ? (
          <>
            <button
              type="button"
              onClick={() => setLightboxOpen(true)}
              className="shrink-0 self-start cursor-zoom-in"
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
        ) : null}
        <div className="min-w-0 flex-1 space-y-2">
          <div className="flex items-start justify-between gap-2">
            <div className="flex min-w-0 flex-1 flex-wrap items-center gap-2">
              <h3 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
                {deal.title || "Untitled deal"}
              </h3>
              {timeBadge && timeBadge !== "—" ? (
                <span className="inline-flex items-center rounded-full bg-zinc-100 px-2.5 py-0.5 text-xs font-medium text-zinc-600 dark:bg-zinc-800 dark:text-zinc-300">
                  {timeBadge}
                </span>
              ) : null}
              {dateBadge ? (
                <span className="inline-flex items-center rounded-full bg-amber-50 px-2.5 py-0.5 text-xs font-medium text-amber-800 dark:bg-amber-950 dark:text-amber-300">
                  {dateBadge}
                </span>
              ) : null}
            </div>
            {onToggleFavorite ? (
              <FavoriteDealButton
                isFavorited={isFavorited ?? false}
                onToggle={onToggleFavorite}
              />
            ) : null}
          </div>
          {showVenue ? (
            <p className="text-sm text-zinc-600 dark:text-zinc-400">
              <Link
                href={venuePath(deal.venue.suburbName, deal.venue.name)}
                className="font-medium text-amber-700 hover:underline dark:text-amber-400"
              >
                {deal.venue.name}
              </Link>
            </p>
          ) : null}
          {dayOfWeek === undefined ? (
            <p className="text-sm font-medium text-zinc-700 dark:text-zinc-300">
              {formatScheduleSummary(deal.schedules)}
            </p>
          ) : null}
          {deal.details ? (
            <MarkdownText className="text-sm text-zinc-700 dark:text-zinc-300">
              {deal.details}
            </MarkdownText>
          ) : null}
          {deal.conditions ? (
            <MarkdownText className="text-sm text-zinc-500 dark:text-zinc-400">
              {deal.conditions}
            </MarkdownText>
          ) : null}
        </div>
      </div>
      {deal.sourceUrl || showReportButton ? (
        <div
          className={`mt-4 flex items-center gap-2 ${deal.sourceUrl ? "justify-between" : "justify-end"}`}
        >
          {deal.sourceUrl ? (
            <a
              href={deal.sourceUrl}
              target="_blank"
              rel="noreferrer"
              className="text-sm text-amber-700 hover:underline dark:text-amber-400"
            >
              View source
            </a>
          ) : null}
          {showReportButton ? <FlagDealButton dealId={deal.id} /> : null}
        </div>
      ) : null}
    </article>
  );
}
