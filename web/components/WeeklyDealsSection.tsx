"use client";

import { useState } from "react";
import { DealCard } from "@/components/DealCard";
import type { DealSearchResult } from "@/lib/search/queries";
import {
  DAY_ABBREVIATIONS,
  DAY_LABELS,
  groupDealsByDay,
  WEEKDAY_UI_ORDER,
} from "@/lib/search/schedule";
import { dealAnchorId } from "@/lib/search/slugs";

type WeeklyDealsSectionProps = {
  deals: DealSearchResult[];
};

function DayFilterPill({
  label,
  ariaLabel,
  isActive,
  onClick,
}: {
  label: string;
  ariaLabel?: string;
  isActive: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-pressed={isActive}
      aria-label={ariaLabel}
      className={`rounded-full border px-3 py-1.5 text-sm font-medium transition-colors ${
        isActive
          ? "border-amber-600 bg-amber-600 text-white dark:border-amber-500 dark:bg-amber-500"
          : "border-zinc-300 text-zinc-700 hover:border-amber-500 hover:bg-amber-50 dark:border-zinc-600 dark:text-zinc-300 dark:hover:border-amber-500 dark:hover:bg-amber-950/30"
      }`}
    >
      {label}
    </button>
  );
}

export function WeeklyDealsSection({ deals }: WeeklyDealsSectionProps) {
  const [selectedDay, setSelectedDay] = useState<number | null>(null);
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
        Weekly Deals ({visibleCount})
      </h2>

      {dealsByDay.length === 0 ? (
        <p className="rounded-xl border border-dashed border-zinc-300 px-4 py-8 text-center text-sm text-zinc-500 dark:border-zinc-700 dark:text-zinc-400">
          No approved deals have been synced for this venue yet.
        </p>
      ) : (
        <>
          <div
            className="flex flex-wrap gap-2"
            role="group"
            aria-label="Filter deals by day"
          >
            <DayFilterPill
              label="Any"
              isActive={selectedDay === null}
              onClick={() => setSelectedDay(null)}
            />
            {WEEKDAY_UI_ORDER.map((day) => (
              <DayFilterPill
                key={day}
                label={DAY_ABBREVIATIONS[day] ?? `Day ${day}`}
                ariaLabel={DAY_LABELS[day]}
                isActive={selectedDay === day}
                onClick={() => setSelectedDay(day)}
              />
            ))}
          </div>

          {selectedDay !== null && filteredDeals!.length === 0 ? (
            <p className="rounded-xl border border-dashed border-zinc-300 px-4 py-8 text-center text-sm text-zinc-500 dark:border-zinc-700 dark:text-zinc-400">
              No deals on {DAY_LABELS[selectedDay]}.
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
                          showVenue={false}
                          dayOfWeek={dayOfWeek}
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
                  showVenue={false}
                  dayOfWeek={selectedDay}
                />
              ))}
            </div>
          )}
        </>
      )}
    </section>
  );
}
