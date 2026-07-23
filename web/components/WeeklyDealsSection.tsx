"use client";

import { useEffect, useState } from "react";
import { usePathname } from "next/navigation";
import { DealCard } from "@/components/DealCard";
import { DealDayFilter } from "@/components/DealDayFilter";
import { useFavorites } from "@/lib/favorites/useFavorites";
import type { DealSearchResult } from "@/lib/search/queries";
import {
  canonicalizeDayHash,
  hashToDayNumber,
  replaceDayHash,
} from "@/lib/search/day-path";
import { DAY_LABELS, groupDealsByDay } from "@/lib/search/schedule";
import { dealAnchorId } from "@/lib/search/slugs";

type WeeklyDealsSectionProps = {
  deals: DealSearchResult[];
  initialSelectedDay?: number | null;
  showVenue?: boolean;
  heading?: (count: number, selectedDay: number | null) => string;
  emptyMessage?: string;
  emptyDayMessage?: (dayLabel: string) => string;
  isFavorite?: (dealId: number) => boolean;
  onToggleFavorite?: (dealId: number) => void;
  showReportButton?: boolean;
  /** When true, sync selected day with `#monday`-style URL hash. */
  syncDayHash?: boolean;
};

const defaultHeading = (count: number, selectedDay: number | null) => {
  if (selectedDay === null) {
    return `Weekly Deals (${count})`;
  }
  const dayLabel = DAY_LABELS[selectedDay] ?? `Day ${selectedDay}`;
  return `${dayLabel} Deals (${count})`;
};
const defaultEmptyMessage =
  "This venue doesn't have any deals. If you know of one, please add it";
const defaultEmptyDayMessage = (dayLabel: string) => `No deals on ${dayLabel}.`;

function dayFromLocationHash(): number | null {
  if (typeof window === "undefined") {
    return null;
  }
  return hashToDayNumber(window.location.hash);
}

export function WeeklyDealsSection({
  deals,
  initialSelectedDay,
  showVenue = false,
  heading = defaultHeading,
  emptyMessage = defaultEmptyMessage,
  emptyDayMessage = defaultEmptyDayMessage,
  isFavorite: isFavoriteProp,
  onToggleFavorite: onToggleFavoriteProp,
  showReportButton = false,
  syncDayHash = false,
}: WeeklyDealsSectionProps) {
  const pathname = usePathname();
  const [selectedDay, setSelectedDay] = useState<number | null>(() => {
    if (syncDayHash) {
      return dayFromLocationHash() ?? initialSelectedDay ?? null;
    }
    return initialSelectedDay ?? null;
  });
  const favorites = useFavorites();
  const isFavorite = isFavoriteProp ?? favorites.isFavorite;
  const toggleFavorite = onToggleFavoriteProp ?? favorites.toggleFavorite;
  const dealsByDay = groupDealsByDay(deals);
  const anchoredDealIds = new Set<number>();

  useEffect(() => {
    if (!syncDayHash) {
      return;
    }

    // Soft nav can leave `#sunday#saturday`; rewrite to a single canonical hash.
    const fromHash = canonicalizeDayHash();
    setSelectedDay(fromHash);

    function onHashChange() {
      setSelectedDay(canonicalizeDayHash());
    }

    window.addEventListener("hashchange", onHashChange);
    return () => window.removeEventListener("hashchange", onHashChange);
  }, [syncDayHash, pathname]);

  function handleSelectedDayChange(day: number | null) {
    setSelectedDay(day);
    if (syncDayHash) {
      replaceDayHash(day);
    }
  }

  const filteredDeals =
    selectedDay === null
      ? null
      : deals.filter((deal) =>
          deal.schedules.some((schedule) => schedule.dayOfWeek === selectedDay),
        );

  const visibleCount =
    selectedDay === null ? deals.length : (filteredDeals?.length ?? 0);

  return (
    <section className="space-y-4">
      <h2 className="text-xl font-semibold text-foreground">
        {heading(visibleCount, selectedDay)}
      </h2>

      {dealsByDay.length === 0 ? (
        <p className="rounded-xl border border-dashed border-border px-4 py-8 text-center text-sm text-muted">
          {emptyMessage}
        </p>
      ) : (
        <>
          <DealDayFilter
            selectedDay={selectedDay}
            onSelectedDayChange={handleSelectedDayChange}
          />

          {selectedDay !== null && filteredDeals!.length === 0 ? (
            <p className="rounded-xl border border-dashed border-border px-4 py-8 text-center text-sm text-muted">
              {emptyDayMessage(DAY_LABELS[selectedDay] ?? `Day ${selectedDay}`)}
            </p>
          ) : selectedDay === null ? (
            <div className="space-y-8">
              {dealsByDay.map(({ dayOfWeek, dayLabel, deals: dayDeals }) => (
                <div key={dayOfWeek} className="space-y-4">
                  <h3 className="border-l-4 border-accent pl-3 text-2xl font-bold text-secondary">
                    {dayLabel}
                  </h3>
                  <div className="grid gap-5">
                    {dayDeals.map((deal) => {
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
                          showVenue={showVenue}
                          dayOfWeek={dayOfWeek}
                          isFavorited={isFavorite(deal.id)}
                          onToggleFavorite={() => toggleFavorite(deal.id)}
                          showReportButton={showReportButton}
                        />
                      );
                    })}
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="grid gap-5">
              {filteredDeals!.map((deal) => (
                <DealCard
                  key={deal.id}
                  id={dealAnchorId(deal.id)}
                  deal={deal}
                  showVenue={showVenue}
                  dayOfWeek={selectedDay}
                  isFavorited={isFavorite(deal.id)}
                  onToggleFavorite={() => toggleFavorite(deal.id)}
                  showReportButton={showReportButton}
                />
              ))}
            </div>
          )}
        </>
      )}
    </section>
  );
}
