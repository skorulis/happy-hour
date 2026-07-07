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

function DayFilterSegment({
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
      className={`min-w-0 flex-1 rounded-lg px-2 py-2 text-sm transition-colors ${
        isActive
          ? "bg-white font-medium text-zinc-900 shadow-sm dark:bg-zinc-900 dark:text-zinc-50"
          : "text-zinc-600 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-zinc-200"
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
      className="overflow-x-auto rounded-xl border border-zinc-200 bg-zinc-100 p-1 dark:border-zinc-700 dark:bg-zinc-900"
      role="group"
      aria-label="Filter deals by day"
    >
      <div className="flex min-w-max gap-0.5">
        <DayFilterSegment
          label="Any"
          isActive={selectedDay === null}
          onClick={() => onSelectedDayChange(null)}
        />
        {WEEKDAY_UI_ORDER.map((day) => (
          <DayFilterSegment
            key={day}
            label={DAY_ABBREVIATIONS[day] ?? `Day ${day}`}
            ariaLabel={DAY_LABELS[day]}
            isActive={selectedDay === day}
            onClick={() => onSelectedDayChange(day)}
          />
        ))}
      </div>
    </div>
  );
}
