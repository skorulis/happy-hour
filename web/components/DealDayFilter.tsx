"use client";

import {
  DAY_ABBREVIATIONS,
  DAY_LABELS,
  WEEKDAY_UI_ORDER,
} from "@/lib/search/schedule";

type DealDayFilterProps = {
  selectedDay: number | null;
  onSelectedDayChange: (day: number | null) => void;
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

export function DealDayFilter({
  selectedDay,
  onSelectedDayChange,
}: DealDayFilterProps) {
  return (
    <div
      className="flex flex-wrap gap-2"
      role="group"
      aria-label="Filter deals by day"
    >
      <DayFilterPill
        label="Any"
        isActive={selectedDay === null}
        onClick={() => onSelectedDayChange(null)}
      />
      {WEEKDAY_UI_ORDER.map((day) => (
        <DayFilterPill
          key={day}
          label={DAY_ABBREVIATIONS[day] ?? `Day ${day}`}
          ariaLabel={DAY_LABELS[day]}
          isActive={selectedDay === day}
          onClick={() => onSelectedDayChange(day)}
        />
      ))}
    </div>
  );
}
