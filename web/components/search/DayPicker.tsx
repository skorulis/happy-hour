"use client";

import { Check, ChevronDown } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import {
  ALL_WEEKDAYS,
  currentCalendarWeekday,
  DAY_LABELS,
  formatDaySelectionLabel,
  snapToTimeFilterHour,
  TIME_FILTER_HOUR_OPTIONS,
  WEEKDAY_UI_ORDER,
} from "@/lib/search/schedule";

export type TimeRange = {
  startMinute?: number;
  endMinute?: number;
} | null;

type DayPickerProps = {
  days: number[];
  timeRange: TimeRange;
  onApply: (days: number[], timeRange: TimeRange) => void;
};

function Checkbox({
  checked,
  onChange,
  label,
  badge,
}: {
  checked: boolean;
  onChange: () => void;
  label: string;
  badge?: string;
}) {
  return (
    <label
      className={`flex cursor-pointer gap-2 py-1.5 text-sm text-zinc-800 dark:text-zinc-200 ${
        badge ? "items-start" : "items-center"
      }`}
    >
      <span
        className={`flex h-4 w-4 shrink-0 items-center justify-center rounded border ${
          checked
            ? "border-amber-600 bg-amber-600 text-white"
            : "border-zinc-300 bg-white dark:border-zinc-600 dark:bg-zinc-950"
        }`}
      >
        {checked ? (
          <Check className="h-3 w-3" strokeWidth={3} />
        ) : null}
      </span>
      <input
        type="checkbox"
        checked={checked}
        onChange={onChange}
        className="sr-only"
      />
      <span className="flex min-w-0 flex-1 flex-col gap-0.5">
        <span>{label}</span>
        {badge ? (
          <span className="self-start rounded bg-amber-600 px-1.5 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-white">
            {badge}
          </span>
        ) : null}
      </span>
    </label>
  );
}

export function DayPicker({ days, timeRange, onApply }: DayPickerProps) {
  const [open, setOpen] = useState(false);
  const [draftDays, setDraftDays] = useState<number[]>(days);
  const [showTimeFilter, setShowTimeFilter] = useState(timeRange !== null);
  const [startMinute, setStartMinute] = useState<number | null>(
    timeRange?.startMinute !== undefined
      ? snapToTimeFilterHour(timeRange.startMinute)
      : null,
  );
  const [endMinute, setEndMinute] = useState<number | null>(
    timeRange?.endMinute !== undefined
      ? snapToTimeFilterHour(timeRange.endMinute)
      : null,
  );
  const containerRef = useRef<HTMLDivElement>(null);
  const today = currentCalendarWeekday();

  useEffect(() => {
    if (!open) {
      return;
    }

    function handlePointerDown(event: MouseEvent) {
      if (
        containerRef.current &&
        !containerRef.current.contains(event.target as Node)
      ) {
        setOpen(false);
      }
    }

    document.addEventListener("mousedown", handlePointerDown);
    return () => document.removeEventListener("mousedown", handlePointerDown);
  }, [open]);

  const allDaysSelected = draftDays.length === ALL_WEEKDAYS.length;
  const label = formatDaySelectionLabel(days);
  const hasSelection = days.length > 0 && days.length < ALL_WEEKDAYS.length;

  function toggleDay(day: number) {
    setDraftDays((current) =>
      current.includes(day)
        ? current.filter((value) => value !== day)
        : [...current, day],
    );
  }

  function toggleAllDays() {
    setDraftDays(allDaysSelected ? [] : [...ALL_WEEKDAYS]);
  }

  function handleClear() {
    setDraftDays([]);
    setShowTimeFilter(false);
    setStartMinute(null);
    setEndMinute(null);
  }

  const timeRangeError =
    showTimeFilter &&
    startMinute !== null &&
    endMinute !== null &&
    endMinute < startMinute
      ? "End time must be after start time"
      : null;

  function buildTimeRange(): TimeRange {
    if (!showTimeFilter || timeRangeError) {
      return null;
    }

    if (startMinute === null && endMinute === null) {
      return null;
    }

    return {
      ...(startMinute !== null ? { startMinute } : {}),
      ...(endMinute !== null ? { endMinute } : {}),
    };
  }

  function handleApply() {
    onApply(draftDays, buildTimeRange());
    setOpen(false);
  }

  const leftColumn = WEEKDAY_UI_ORDER.slice(0, 4);
  const rightColumn = WEEKDAY_UI_ORDER.slice(4);

  return (
    <div ref={containerRef} className="relative">
      <button
        type="button"
        onClick={() => {
          if (!open) {
            setDraftDays(days);
            setShowTimeFilter(timeRange !== null);
            setStartMinute(
              timeRange?.startMinute !== undefined
                ? snapToTimeFilterHour(timeRange.startMinute)
                : null,
            );
            setEndMinute(
              timeRange?.endMinute !== undefined
                ? snapToTimeFilterHour(timeRange.endMinute)
                : null,
            );
          }
          setOpen((current) => !current);
        }}
        className={`inline-flex items-center gap-2 rounded-full border px-4 py-2 text-sm font-medium transition-colors ${
          hasSelection || timeRange
            ? "border-amber-600 text-amber-700 dark:border-amber-500 dark:text-amber-400"
            : "border-zinc-300 text-zinc-700 hover:border-amber-500 dark:border-zinc-600 dark:text-zinc-300"
        }`}
      >
        {label}
        <ChevronDown
          aria-hidden
          className={`h-4 w-4 transition-transform ${open ? "rotate-180" : ""}`}
        />
      </button>

      {open ? (
        <div className="absolute left-0 z-20 mt-2 w-72 rounded-xl border border-zinc-200 bg-white p-4 shadow-lg dark:border-zinc-700 dark:bg-zinc-900">
          <div className="grid grid-cols-2 gap-x-4">
            <div className="min-w-0">
              {leftColumn.map((day) => (
                <Checkbox
                  key={day}
                  checked={draftDays.includes(day)}
                  onChange={() => toggleDay(day)}
                  label={DAY_LABELS[day]}
                  badge={day === today ? "Today" : undefined}
                />
              ))}
            </div>
            <div className="min-w-0">
              {rightColumn.map((day) => (
                <Checkbox
                  key={day}
                  checked={draftDays.includes(day)}
                  onChange={() => toggleDay(day)}
                  label={DAY_LABELS[day]}
                  badge={day === today ? "Today" : undefined}
                />
              ))}
            </div>
          </div>

          <div className="my-3 border-t border-zinc-200 dark:border-zinc-700" />

          <Checkbox
            checked={allDaysSelected}
            onChange={toggleAllDays}
            label="All days"
          />

          <div className="my-3 border-t border-zinc-200 dark:border-zinc-700" />

          {!showTimeFilter ? (
            <button
              type="button"
              onClick={() => {
                setShowTimeFilter(true);
                setStartMinute(null);
                setEndMinute(null);
              }}
              className="text-sm text-zinc-500 hover:text-zinc-700 dark:text-zinc-400 dark:hover:text-zinc-200"
            >
              + Filter by time
            </button>
          ) : (
            <div className="space-y-2">
              <p className="text-sm font-medium text-zinc-700 dark:text-zinc-300">
                Time range
              </p>
              <div className="grid grid-cols-2 gap-2">
                <select
                  value={startMinute ?? ""}
                  onChange={(event) => {
                    const value = event.target.value;
                    setStartMinute(value === "" ? null : Number(value));
                  }}
                  aria-label="Start time"
                  className="rounded-lg border border-zinc-300 bg-white px-3 py-2 text-sm text-zinc-900 outline-none ring-amber-500 focus:ring-2 dark:border-zinc-600 dark:bg-zinc-950 dark:text-zinc-50"
                >
                  <option value="">Any</option>
                  {TIME_FILTER_HOUR_OPTIONS.map((option) => (
                    <option key={option.value} value={option.value}>
                      {option.label}
                    </option>
                  ))}
                </select>
                <select
                  value={endMinute ?? ""}
                  onChange={(event) => {
                    const value = event.target.value;
                    setEndMinute(value === "" ? null : Number(value));
                  }}
                  aria-label="End time"
                  className="rounded-lg border border-zinc-300 bg-white px-3 py-2 text-sm text-zinc-900 outline-none ring-amber-500 focus:ring-2 dark:border-zinc-600 dark:bg-zinc-950 dark:text-zinc-50"
                >
                  <option value="">Any</option>
                  {TIME_FILTER_HOUR_OPTIONS.map((option) => (
                    <option key={option.value} value={option.value}>
                      {option.label}
                    </option>
                  ))}
                </select>
              </div>
              {timeRangeError ? (
                <p className="text-xs text-red-600 dark:text-red-400">
                  {timeRangeError}
                </p>
              ) : null}
              <button
                type="button"
                onClick={() => {
                  setShowTimeFilter(false);
                  setStartMinute(null);
                  setEndMinute(null);
                }}
                className="text-xs text-zinc-500 hover:text-zinc-700 dark:text-zinc-400"
              >
                Remove time filter
              </button>
            </div>
          )}

          <div className="my-3 border-t border-zinc-200 dark:border-zinc-700" />

          <div className="flex items-center justify-between">
            <button
              type="button"
              onClick={handleClear}
              className="text-sm text-zinc-500 hover:text-zinc-700 dark:text-zinc-400 dark:hover:text-zinc-200"
            >
              Clear
            </button>
            <button
              type="button"
              onClick={handleApply}
              className="rounded-lg bg-amber-600 px-4 py-2 text-sm font-medium text-white hover:bg-amber-700"
            >
              Apply
            </button>
          </div>
        </div>
      ) : null}
    </div>
  );
}
