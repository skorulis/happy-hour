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
  onPointerDown?: () => void;
  className?: string;
};

function SegmentButton({
  label,
  value,
  isPlaceholder,
  isActive,
  hasOpenSegment,
  onClick,
  onPointerDown,
  className = "",
}: SegmentButtonProps) {
  return (
    <button
      type="button"
      onPointerDown={onPointerDown}
      onClick={onClick}
      className={`flex min-w-0 flex-1 flex-col rounded-lg px-5 py-3 text-left transition-all md:rounded-full md:py-3.5 ${
        isActive
          ? "bg-surface-elevated shadow-md md:shadow-md"
          : hasOpenSegment
            ? "bg-transparent hover:bg-surface-muted"
            : "bg-transparent hover:bg-surface-muted"
      } ${className}`}
    >
      <span className="text-xs font-semibold text-secondary">
        {label}
      </span>
      <span
        className={`truncate text-sm ${
          isPlaceholder
            ? "text-muted"
            : "font-medium text-foreground"
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
  onInputBlur,
  onClose,
}: {
  segment: ActiveSegment;
  filters: SearchFilters;
  onDaysApply: (days: number[], timeRange: TimeRange) => void;
  onWhereChange: (where: WhereFilter) => void;
  onWhatChange: (what: string[]) => void;
  onInputBlur?: () => void;
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
        onInputBlur={onInputBlur}
        open={open}
      />
    );
  }

  return (
    <WhatSelectPanel
      tokens={filters.what}
      onChange={onWhatChange}
      onClose={onClose}
      onInputBlur={onInputBlur}
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
  const ignoreInputBlurCloseRef = useRef(false);
  const pendingInputBlurCloseRef = useRef<ReturnType<typeof setTimeout> | null>(
    null,
  );

  const visibleSegments = buildSegmentConfigs(filters).filter((segment) =>
    segments.includes(segment.id),
  );

  function toggleSegment(segment: SearchBarSegment) {
    setActiveSegment((current) => (current === segment ? null : segment));
  }

  function closePanel() {
    if (pendingInputBlurCloseRef.current) {
      clearTimeout(pendingInputBlurCloseRef.current);
      pendingInputBlurCloseRef.current = null;
    }
    setActiveSegment(null);
  }

  function handleSegmentPointerDown() {
    ignoreInputBlurCloseRef.current = true;
    if (pendingInputBlurCloseRef.current) {
      clearTimeout(pendingInputBlurCloseRef.current);
      pendingInputBlurCloseRef.current = null;
    }
  }

  function handleSegmentClick(segment: SearchBarSegment) {
    toggleSegment(segment);
    window.setTimeout(() => {
      ignoreInputBlurCloseRef.current = false;
    }, 0);
  }

  function scheduleInputPanelClose() {
    if (ignoreInputBlurCloseRef.current) {
      return;
    }

    if (pendingInputBlurCloseRef.current) {
      clearTimeout(pendingInputBlurCloseRef.current);
    }

    pendingInputBlurCloseRef.current = window.setTimeout(() => {
      pendingInputBlurCloseRef.current = null;
      if (!ignoreInputBlurCloseRef.current) {
        setActiveSegment(null);
      }
    }, 150);
  }

  const openSegment =
    activeSegment && segments.includes(activeSegment) ? activeSegment : null;

  useEffect(() => {
    return () => {
      if (pendingInputBlurCloseRef.current) {
        clearTimeout(pendingInputBlurCloseRef.current);
      }
    };
  }, []);

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
        className={`relative rounded-2xl border border-border shadow-md transition-colors md:rounded-full ${
          hasOpenSegment
            ? "bg-surface-muted"
            : "bg-surface-elevated"
        }`}
      >
        {/* Desktop: horizontal pill */}
        <div className="hidden items-center md:flex">
          {visibleSegments.map((segment, index) => (
            <div key={segment.id} className="contents">
              {index > 0 ? (
                <div
                  aria-hidden
                  className="h-8 w-px shrink-0 bg-border"
                />
              ) : null}
              <SegmentButton
                label={segment.label}
                value={segment.value}
                isPlaceholder={segment.isPlaceholder}
                isActive={openSegment === segment.id}
                hasOpenSegment={hasOpenSegment}
                onClick={() => handleSegmentClick(segment.id)}
                onPointerDown={handleSegmentPointerDown}
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
                  className="h-px bg-border"
                />
              ) : null}
              <div className="relative">
                <SegmentButton
                  label={segment.label}
                  value={segment.value}
                  isPlaceholder={segment.isPlaceholder}
                  isActive={openSegment === segment.id}
                  hasOpenSegment={hasOpenSegment}
                  onClick={() => handleSegmentClick(segment.id)}
                  onPointerDown={handleSegmentPointerDown}
                  className="w-full px-6"
                />
                {openSegment === segment.id ? (
                  <div className="border-t border-border-subtle px-4 py-3">
                    <ActivePanel
                      segment={segment.id}
                      filters={filters}
                      onDaysApply={onDaysApply}
                      onWhereChange={handleWhereChange}
                      onWhatChange={onWhatChange}
                      onInputBlur={scheduleInputPanelClose}
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
              onInputBlur={scheduleInputPanelClose}
              onClose={closePanel}
            />
          </div>
        ) : null}
      </div>
    </section>
  );
}
