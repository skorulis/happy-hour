"use client";

import { useState } from "react";
import {
  currentCalendarWeekday,
  DAY_LABELS,
  snapToTimeFilterHour,
  TIME_FILTER_HOUR_OPTIONS,
  WEEKDAY_UI_ORDER,
} from "@/lib/search/schedule";

export type TimeRange = {
  startMinute?: number;
  endMinute?: number;
} | null;

type DayPickerPanelProps = {
  days: number[];
  timeRange: TimeRange;
  onApply: (days: number[], timeRange: TimeRange) => void;
  onClose: () => void;
  open: boolean;
};

/** Single day kept; multi-day / empty / all-seven collapse to All days (`[]`). */
function initialDraftDays(days: number[]): number[] {
  return days.length === 1 ? days : [];
}

function Radio({
  checked,
  onChange,
  name,
  value,
  label,
  badge,
}: {
  checked: boolean;
  onChange: () => void;
  name: string;
  value: string;
  label: string;
  badge?: string;
}) {
  return (
    <label
      className={`flex cursor-pointer gap-2 py-1.5 text-sm text-secondary ${
        badge ? "items-start" : "items-center"
      }`}
    >
      <span
        className={`flex h-4 w-4 shrink-0 items-center justify-center rounded-full border ${
          checked ? "border-accent bg-accent" : "border-border bg-surface"
        }`}
      >
        {checked ? (
          <span className="h-1.5 w-1.5 rounded-full bg-accent-fg" />
        ) : null}
      </span>
      <input
        type="radio"
        name={name}
        value={value}
        checked={checked}
        onChange={onChange}
        className="sr-only"
      />
      <span className="flex min-w-0 flex-1 flex-col gap-0.5">
        <span>{label}</span>
        {badge ? (
          <span className="self-start rounded bg-accent px-1.5 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-accent-fg">
            {badge}
          </span>
        ) : null}
      </span>
    </label>
  );
}

export function DayPickerPanel({
  days,
  timeRange,
  onApply,
  onClose,
}: DayPickerPanelProps) {
  const [draftDays, setDraftDays] = useState<number[]>(() =>
    initialDraftDays(days),
  );
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
  const today = currentCalendarWeekday();

  const selectedDay = draftDays.length === 1 ? draftDays[0]! : null;
  const allDaysSelected = selectedDay === null;

  function selectDay(day: number) {
    setDraftDays([day]);
  }

  function selectAllDays() {
    setDraftDays([]);
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
    onClose();
  }

  const leftColumn = WEEKDAY_UI_ORDER.slice(0, 4);
  const rightColumn = WEEKDAY_UI_ORDER.slice(4);

  return (
    <div className="w-72 max-w-[calc(100vw-3rem)] rounded-xl border border-border bg-surface-elevated p-4 shadow-card">
      <div className="grid grid-cols-2 gap-x-4">
        <div className="min-w-0">
          {leftColumn.map((day) => (
            <Radio
              key={day}
              name="day-filter"
              value={String(day)}
              checked={selectedDay === day}
              onChange={() => selectDay(day)}
              label={DAY_LABELS[day]}
              badge={day === today ? "Today" : undefined}
            />
          ))}
        </div>
        <div className="min-w-0">
          {rightColumn.map((day) => (
            <Radio
              key={day}
              name="day-filter"
              value={String(day)}
              checked={selectedDay === day}
              onChange={() => selectDay(day)}
              label={DAY_LABELS[day]}
              badge={day === today ? "Today" : undefined}
            />
          ))}
          <Radio
            name="day-filter"
            value="all"
            checked={allDaysSelected}
            onChange={selectAllDays}
            label="All days"
          />
        </div>
      </div>

      <div className="my-3 border-t border-border-subtle" />

      {!showTimeFilter ? (
        <button
          type="button"
          onClick={() => {
            setShowTimeFilter(true);
            setStartMinute(null);
            setEndMinute(null);
          }}
          className="text-sm text-muted hover:text-foreground"
        >
          + Filter by time
        </button>
      ) : (
        <div className="space-y-2">
          <p className="text-sm font-medium text-secondary">
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
              className="rounded-lg border border-border bg-surface px-3 py-2 text-sm text-foreground outline-none ring-accent focus:ring-2"
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
              className="rounded-lg border border-border bg-surface px-3 py-2 text-sm text-foreground outline-none ring-accent focus:ring-2"
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
            <p className="text-xs text-danger">
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
            className="text-xs text-muted hover:text-foreground"
          >
            Remove time filter
          </button>
        </div>
      )}

      <div className="my-3 border-t border-border-subtle" />

      <div className="flex items-center justify-between">
        <button
          type="button"
          onClick={handleClear}
          className="text-sm text-muted hover:text-foreground"
        >
          Clear
        </button>
        <button
          type="button"
          onClick={handleApply}
          className="rounded-lg bg-accent px-4 py-2 text-sm font-medium text-accent-fg hover:bg-accent-hover"
        >
          Apply
        </button>
      </div>
    </div>
  );
}
