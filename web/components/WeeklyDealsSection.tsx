"use client";

import { useState } from "react";
import { DealCard } from "@/components/DealCard";
import { DealDayFilter } from "@/components/DealDayFilter";
import { useFavorites } from "@/lib/favorites/useFavorites";
import type { DealSearchResult } from "@/lib/search/queries";
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
};

const defaultHeading = (count: number, selectedDay: number | null) => {
  if (selectedDay === null) {
    return `Weekly Deals (${count})`;
  }
  const dayLabel = DAY_LABELS[selectedDay] ?? `Day ${selectedDay}`;
  return `${dayLabel} Deals (${count})`;
};
const defaultEmptyMessage =
  "No approved deals have been synced for this venue yet.";
const defaultEmptyDayMessage = (dayLabel: string) => `No deals on ${dayLabel}.`;

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
}: WeeklyDealsSectionProps) {
  const [selectedDay, setSelectedDay] = useState<number | null>(
    initialSelectedDay ?? null,
  );
  const favorites = useFavorites();
  const isFavorite = isFavoriteProp ?? favorites.isFavorite;
  const toggleFavorite = onToggleFavoriteProp ?? favorites.toggleFavorite;
  const dealsByDay = groupDealsByDay(deals);
  const anchoredDealIds = new Set<number>();

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
      <h2 className="text-xl font-semibold text-zinc-900 dark:text-zinc-50">
        {heading(visibleCount, selectedDay)}
      </h2>

      {dealsByDay.length === 0 ? (
        <p className="rounded-xl border border-dashed border-zinc-300 px-4 py-8 text-center text-sm text-zinc-500 dark:border-zinc-700 dark:text-zinc-400">
          {emptyMessage}
        </p>
      ) : (
        <>
          <DealDayFilter
            selectedDay={selectedDay}
            onSelectedDayChange={setSelectedDay}
          />

          {selectedDay !== null && filteredDeals!.length === 0 ? (
            <p className="rounded-xl border border-dashed border-zinc-300 px-4 py-8 text-center text-sm text-zinc-500 dark:border-zinc-700 dark:text-zinc-400">
              {emptyDayMessage(DAY_LABELS[selectedDay] ?? `Day ${selectedDay}`)}
            </p>
          ) : selectedDay === null ? (
            <div className="space-y-8">
              {dealsByDay.map(({ dayOfWeek, dayLabel, deals: dayDeals }) => (
                <div key={dayOfWeek} className="space-y-4">
                  <h3 className="text-2xl font-bold text-zinc-700 dark:text-zinc-300">
                    {dayLabel}
                  </h3>
                  <div className="grid gap-4">
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
            <div className="grid gap-4">
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
