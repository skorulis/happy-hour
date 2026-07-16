"use client";

import { DayPickerPanel, type TimeRange } from "@/components/search/DayPicker";
import {
  formatWhereLabel,
  SuburbSelectPanel,
  type WhereFilter,
} from "@/components/search/SuburbSelect";
import { WhatSelectPanel } from "@/components/search/WhatSelect";
import {
  ALL_WEEKDAYS,
  formatDaySelectionLabel,
  formatHourDropdownLabel,
} from "@/lib/search/schedule";
import { useEffect, useRef, useState } from "react";

export type { TimeRange, WhereFilter };

export type SearchFilters = {
  days: number[];
  timeRange: TimeRange;
  where: WhereFilter;
  what: string[];
};

export type SearchBarSegment = "when" | "where" | "what";

const DEFAULT_SEGMENTS: SearchBarSegment[] = ["when", "where", "what"];

type SearchBarProps = {
  filters: SearchFilters;
  onDaysApply: (days: number[], timeRange: TimeRange) => void;
  onWhatChange: (what: string[]) => void;
  onWhereChange?: (where: WhereFilter) => void;
  segments?: SearchBarSegment[];
  className?: string;
};

type ActiveSegment = SearchBarSegment | null;

function formatWhenValue(days: number[], timeRange: TimeRange): string {
  let label = formatDaySelectionLabel(days);
  if (timeRange) {
    const parts: string[] = [];
    if (timeRange.startMinute !== undefined) {
      parts.push(formatHourDropdownLabel(timeRange.startMinute));
    }
    if (timeRange.endMinute !== undefined) {
      parts.push(formatHourDropdownLabel(timeRange.endMinute));
    }
    if (parts.length > 0) {
      label = `${label} · ${parts.join("–")}`;
    }
  }
  return label;
}

function isWhenPlaceholder(days: number[], timeRange: TimeRange): boolean {
  return (
    (days.length === 0 || days.length === ALL_WEEKDAYS.length) &&
    timeRange === null
  );
}

function isWherePlaceholder(where: WhereFilter): boolean {
  return where.kind === "anywhere";
}

function isWhatPlaceholder(what: string[]): boolean {
  return what.length === 0;
}

type SegmentButtonProps = {
  label: string;
  value: string;
  isPlaceholder: boolean;
  isActive: boolean;
  hasOpenSegment: boolean;
  onClick: () => void;
  className?: string;
};

function SegmentButton({
  label,
  value,
  isPlaceholder,
  isActive,
  hasOpenSegment,
  onClick,
  className = "",
}: SegmentButtonProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex min-w-0 flex-1 flex-col rounded-lg px-5 py-3 text-left transition-all md:rounded-full md:py-3.5 ${
        isActive
          ? "bg-white shadow-md dark:bg-zinc-900 md:shadow-md"
          : hasOpenSegment
            ? "bg-transparent hover:bg-zinc-200/60 dark:hover:bg-zinc-800/60"
            : "bg-transparent hover:bg-zinc-100 dark:hover:bg-zinc-800/50"
      } ${className}`}
    >
      <span className="text-xs font-semibold text-zinc-800 dark:text-zinc-200">
        {label}
      </span>
      <span
        className={`truncate text-sm ${
          isPlaceholder
            ? "text-zinc-400 dark:text-zinc-500"
            : "font-medium text-zinc-900 dark:text-zinc-50"
        }`}
      >
        {value}
      </span>
    </button>
  );
}

function ActivePanel({
  segment,
  filters,
  onDaysApply,
  onWhereChange,
  onWhatChange,
  onClose,
}: {
  segment: ActiveSegment;
  filters: SearchFilters;
  onDaysApply: (days: number[], timeRange: TimeRange) => void;
  onWhereChange: (where: WhereFilter) => void;
  onWhatChange: (what: string[]) => void;
  onClose: () => void;
}) {
  if (!segment) {
    return null;
  }

  const open = true;

  if (segment === "when") {
    return (
      <DayPickerPanel
        days={filters.days}
        timeRange={filters.timeRange}
        onApply={onDaysApply}
        onClose={onClose}
        open={open}
      />
    );
  }

  if (segment === "where") {
    return (
      <SuburbSelectPanel
        where={filters.where}
        onChange={onWhereChange}
        onClose={onClose}
        open={open}
      />
    );
  }

  return (
    <WhatSelectPanel
      tokens={filters.what}
      onChange={onWhatChange}
      onClose={onClose}
      open={open}
    />
  );
}

type SegmentConfig = {
  id: SearchBarSegment;
  label: string;
  value: string;
  isPlaceholder: boolean;
};

function buildSegmentConfigs(filters: SearchFilters): SegmentConfig[] {
  return [
    {
      id: "when",
      label: "When",
      value: formatWhenValue(filters.days, filters.timeRange),
      isPlaceholder: isWhenPlaceholder(filters.days, filters.timeRange),
    },
    {
      id: "where",
      label: "Where",
      value: formatWhereLabel(filters.where),
      isPlaceholder: isWherePlaceholder(filters.where),
    },
    {
      id: "what",
      label: "What",
      value: filters.what.length > 0 ? filters.what.join(", ") : "Any deals",
      isPlaceholder: isWhatPlaceholder(filters.what),
    },
  ];
}

function desktopPopoverAlign(
  segment: SearchBarSegment,
  visibleSegments: SearchBarSegment[],
): string {
  if (visibleSegments.length === 1) {
    return "left-0";
  }
  if (visibleSegments.length === 2) {
    return segment === "what" ? "right-0" : "left-0";
  }
  if (segment === "when") {
    return "left-0";
  }
  if (segment === "where") {
    return "left-1/2 -translate-x-1/2";
  }
  return "right-0";
}

function desktopSegmentClassName(
  segment: SearchBarSegment,
  visibleSegments: SearchBarSegment[],
): string {
  const index = visibleSegments.indexOf(segment);
  const isFirst = index === 0;
  const isLast = index === visibleSegments.length - 1;

  if (isFirst && isLast) {
    return "rounded-full px-6";
  }
  if (isFirst) {
    return "rounded-l-full pl-6";
  }
  if (isLast) {
    return "rounded-r-full pr-6";
  }
  return "";
}

export function SearchBar({
  filters,
  onDaysApply,
  onWhereChange,
  onWhatChange,
  segments = DEFAULT_SEGMENTS,
  className = "",
}: SearchBarProps) {
  const [activeSegment, setActiveSegment] = useState<ActiveSegment>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  const visibleSegments = buildSegmentConfigs(filters).filter((segment) =>
    segments.includes(segment.id),
  );

  function toggleSegment(segment: SearchBarSegment) {
    setActiveSegment((current) => (current === segment ? null : segment));
  }

  function closePanel() {
    setActiveSegment(null);
  }

  const openSegment =
    activeSegment && segments.includes(activeSegment) ? activeSegment : null;

  useEffect(() => {
    if (!openSegment) {
      return;
    }

    function handlePointerDown(event: MouseEvent) {
      if (
        containerRef.current &&
        !containerRef.current.contains(event.target as Node)
      ) {
        setActiveSegment(null);
      }
    }

    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === "Escape") {
        setActiveSegment(null);
      }
    }

    document.addEventListener("mousedown", handlePointerDown);
    document.addEventListener("keydown", handleKeyDown);
    return () => {
      document.removeEventListener("mousedown", handlePointerDown);
      document.removeEventListener("keydown", handleKeyDown);
    };
  }, [openSegment]);

  const hasOpenSegment = openSegment !== null;
  const handleWhereChange = onWhereChange ?? (() => {});

  return (
    <section
      ref={containerRef}
      className={`mx-auto w-full max-w-3xl ${className}`}
    >
      <div
        className={`relative rounded-2xl border border-zinc-300 shadow-md transition-colors md:rounded-full dark:border-zinc-600 ${
          hasOpenSegment
            ? "bg-zinc-100 dark:bg-zinc-800/80"
            : "bg-white dark:bg-zinc-900"
        }`}
      >
        {/* Desktop: horizontal pill */}
        <div className="hidden items-center md:flex">
          {visibleSegments.map((segment, index) => (
            <div key={segment.id} className="contents">
              {index > 0 ? (
                <div
                  aria-hidden
                  className="h-8 w-px shrink-0 bg-zinc-300 dark:bg-zinc-600"
                />
              ) : null}
              <SegmentButton
                label={segment.label}
                value={segment.value}
                isPlaceholder={segment.isPlaceholder}
                isActive={openSegment === segment.id}
                hasOpenSegment={hasOpenSegment}
                onClick={() => toggleSegment(segment.id)}
                className={desktopSegmentClassName(
                  segment.id,
                  segments,
                )}
              />
            </div>
          ))}
        </div>

        {/* Mobile: stacked segments */}
        <div className="flex flex-col md:hidden">
          {visibleSegments.map((segment, index) => (
            <div key={segment.id}>
              {index > 0 ? (
                <div
                  aria-hidden
                  className="h-px bg-zinc-300 dark:bg-zinc-600"
                />
              ) : null}
              <div className="relative">
                <SegmentButton
                  label={segment.label}
                  value={segment.value}
                  isPlaceholder={segment.isPlaceholder}
                  isActive={openSegment === segment.id}
                  hasOpenSegment={hasOpenSegment}
                  onClick={() => toggleSegment(segment.id)}
                  className="w-full px-6"
                />
                {openSegment === segment.id ? (
                  <div className="border-t border-zinc-200 px-4 py-3 dark:border-zinc-700">
                    <ActivePanel
                      segment={segment.id}
                      filters={filters}
                      onDaysApply={onDaysApply}
                      onWhereChange={handleWhereChange}
                      onWhatChange={onWhatChange}
                      onClose={closePanel}
                    />
                  </div>
                ) : null}
              </div>
            </div>
          ))}
        </div>

        {/* Desktop: shared popover */}
        {openSegment ? (
          <div
            className={`absolute top-full z-20 mt-3 hidden md:block ${desktopPopoverAlign(openSegment, segments)}`}
          >
            <ActivePanel
              segment={openSegment}
              filters={filters}
              onDaysApply={onDaysApply}
              onWhereChange={handleWhereChange}
              onWhatChange={onWhatChange}
              onClose={closePanel}
            />
          </div>
        ) : null}
      </div>
    </section>
  );
}
