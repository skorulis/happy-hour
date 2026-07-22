export const DAY_LABELS: Record<number, string> = {
  1: "Sunday",
  2: "Monday",
  3: "Tuesday",
  4: "Wednesday",
  5: "Thursday",
  6: "Friday",
  7: "Saturday",
};

export const DAY_OPTIONS = Object.entries(DAY_LABELS).map(([value, label]) => ({
  value: Number(value),
  label,
}));

/** Mon → Sun display order (calendar weekday values 2–7, 1). */
export const WEEKDAY_UI_ORDER = [2, 3, 4, 5, 6, 7, 1] as const;

export const DAY_ABBREVIATIONS: Record<number, string> = {
  1: "Sun",
  2: "Mon",
  3: "Tue",
  4: "Wed",
  5: "Thu",
  6: "Fri",
  7: "Sat",
};

export const ALL_WEEKDAYS = [1, 2, 3, 4, 5, 6, 7];

export function formatDaySelectionLabel(days: number[]): string {
  if (days.length === 0) {
    return "Today";
  }

  if (days.length === ALL_WEEKDAYS.length) {
    return "Any day";
  }

  const sorted = [...days].sort(
    (a, b) =>
      WEEKDAY_UI_ORDER.indexOf(a as (typeof WEEKDAY_UI_ORDER)[number]) -
      WEEKDAY_UI_ORDER.indexOf(b as (typeof WEEKDAY_UI_ORDER)[number]),
  );

  if (sorted.length <= 2) {
    return sorted.map((day) => DAY_ABBREVIATIONS[day] ?? `Day ${day}`).join(", ");
  }

  return `${sorted.length} days`;
}

function formatSpecialsTitleBase(
  days: number[],
  what: string[] = [],
): string {
  const dayLabel = suburbTitleDayLabel(days);
  const productLabel = suburbTitleProductLabel(what);
  const specialsPhrase = productLabel ? `${productLabel} Specials` : "Specials";
  return dayLabel ? `${dayLabel} ${specialsPhrase}` : specialsPhrase;
}

export function formatSuburbDealsTitle(
  suburbName: string,
  days: number[],
  what: string[] = [],
): string {
  return `${formatSpecialsTitleBase(days, what)} in ${suburbName}`;
}

export function formatNearbyDealsTitle(
  days: number[],
  what: string[] = [],
): string {
  return `${formatSpecialsTitleBase(days, what)} Nearby`;
}

export function formatSuburbDealsMetadataTitle(
  suburbName: string,
  days: number[],
  what: string[] = [],
): string {
  // Bare suburb URLs SSR the full week; omit weekday so the title matches that body.
  // Explicit single-day ?days= still gets a weekday prefix.
  if (days.length === 0) {
    return formatSuburbDealsTitle(suburbName, ALL_WEEKDAYS, what);
  }
  return formatSuburbDealsTitle(suburbName, days, what);
}

/** Single selected day, or today when none selected (implicit today search). */
function suburbTitleDayLabel(days: number[]): string | null {
  if (days.length > 1) {
    return null;
  }
  const day = days.length === 0 ? currentCalendarWeekday() : days[0];
  return DAY_LABELS[day] ?? null;
}

/** One or two product names for the title; 0 or 3+ falls back to generic Specials. */
function suburbTitleProductLabel(what: string[]): string | null {
  if (what.length === 0 || what.length > 2) {
    return null;
  }
  const labels = what.map(titleCaseWords);
  if (labels.length === 1) {
    return labels[0]!;
  }
  return `${labels[0]} and ${labels[1]}`;
}

function titleCaseWords(value: string): string {
  return value
    .split(/\s+/)
    .filter((word) => word.length > 0)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
    .join(" ");
}

export function parseTimeInput(value: string): number | null {
  const trimmed = value.trim().toLowerCase();
  const match = trimmed.match(/^(\d{1,2})(?::(\d{2}))?\s*(am|pm)?$/);
  if (!match) {
    return null;
  }

  let hours = Number(match[1]);
  const minutes = match[2] ? Number(match[2]) : 0;
  const meridiem = match[3];

  if (minutes < 0 || minutes > 59 || hours < 0 || hours > 12) {
    return null;
  }

  if (meridiem) {
    if (hours === 12) {
      hours = meridiem === "am" ? 0 : 12;
    } else if (meridiem === "pm") {
      hours += 12;
    }
  } else if (hours > 23) {
    return null;
  }

  return hours * 60 + minutes;
}

export function formatTimeInput(minute: number): string {
  return formatMinute(minute);
}

export const TIME_FILTER_START_MINUTE = 10 * 60;
export const TIME_FILTER_END_MINUTE = 24 * 60;

export function formatHourDropdownLabel(minute: number): string {
  if (minute === TIME_FILTER_END_MINUTE) {
    return "12am";
  }

  const hours24 = Math.floor(minute / 60);
  const suffix = hours24 >= 12 ? "pm" : "am";
  const hours12 = hours24 % 12 || 12;
  return `${hours12}${suffix}`;
}

export const TIME_FILTER_HOUR_OPTIONS = Array.from(
  {
    length:
      (TIME_FILTER_END_MINUTE - TIME_FILTER_START_MINUTE) / 60 + 1,
  },
  (_, index) => {
    const minute = TIME_FILTER_START_MINUTE + index * 60;
    return {
      value: minute,
      label: formatHourDropdownLabel(minute),
    };
  },
);

export function snapToTimeFilterHour(minute: number): number {
  const snapped = Math.round(minute / 60) * 60;
  return Math.min(
    TIME_FILTER_END_MINUTE,
    Math.max(TIME_FILTER_START_MINUTE, snapped),
  );
}

/** Matches DealDay.calendarWeekday in the Swift app (1 = Sunday … 7 = Saturday). */
export function currentCalendarWeekday(date = new Date()): number {
  return date.getDay() + 1;
}

export function currentMinuteOfDay(date = new Date()): number {
  return date.getHours() * 60 + date.getMinutes();
}

export function minutesWithinDay(minute: number): number {
  return minute % 1440;
}

export function formatMinute(minute: number): string {
  const hours24 = Math.floor(minutesWithinDay(minute) / 60);
  const minutes = minutesWithinDay(minute) % 60;
  const suffix = hours24 >= 12 ? "pm" : "am";
  const hours12 = hours24 % 12 || 12;
  return `${hours12}:${minutes.toString().padStart(2, "0")}${suffix}`;
}

export type ScheduleSlice = {
  dayOfWeek: number;
  startMinute: number;
  endMinute: number;
};

export function isAllDaySchedule(startMinute: number, endMinute: number): boolean {
  return startMinute === 0 && endMinute === 1440;
}

export function schedulesForDay(
  schedules: ScheduleSlice[],
  dayOfWeek: number,
): ScheduleSlice[] {
  return schedules.filter((schedule) => schedule.dayOfWeek === dayOfWeek);
}

function previousCalendarWeekday(day: number): number {
  return day === 1 ? 7 : day - 1;
}

/** Whether a single schedule row is active at the given moment. */
export function isScheduleActiveNow(
  schedule: ScheduleSlice,
  now = new Date(),
): boolean {
  const day = currentCalendarWeekday(now);
  const minute = currentMinuteOfDay(now);
  const previousDay = previousCalendarWeekday(day);

  if (
    schedule.dayOfWeek === day &&
    schedule.startMinute <= minute &&
    schedule.endMinute > minute
  ) {
    return true;
  }

  if (
    schedule.dayOfWeek === previousDay &&
    schedule.endMinute > 1440 &&
    minute < schedule.endMinute - 1440
  ) {
    return true;
  }

  return false;
}

export function isDealActiveNow(
  schedules: ScheduleSlice[],
  now = new Date(),
): boolean {
  return schedules.some((schedule) => isScheduleActiveNow(schedule, now));
}

export function hasAnyDealActiveNow<
  T extends { schedules: ScheduleSlice[] },
>(deals: T[], now = new Date()): boolean {
  return deals.some((deal) => isDealActiveNow(deal.schedules, now));
}

export function sortDealsActiveFirst<
  T extends { schedules: ScheduleSlice[] },
>(deals: T[], now = new Date()): T[] {
  const active: T[] = [];
  const inactive: T[] = [];

  for (const deal of deals) {
    if (isDealActiveNow(deal.schedules, now)) {
      active.push(deal);
    } else {
      inactive.push(deal);
    }
  }

  return [...active, ...inactive];
}

export function groupDealsByDay<T extends { id: number; schedules: ScheduleSlice[] }>(
  deals: T[],
): Array<{ dayOfWeek: number; dayLabel: string; deals: T[] }> {
  const dealsByDay = new Map<number, T[]>();

  for (const deal of deals) {
    const days = [...new Set(deal.schedules.map((schedule) => schedule.dayOfWeek))];
    for (const day of days) {
      const existing = dealsByDay.get(day) ?? [];
      if (!existing.some((item) => item.id === deal.id)) {
        existing.push(deal);
        dealsByDay.set(day, existing);
      }
    }
  }

  return WEEKDAY_UI_ORDER.filter((day) => dealsByDay.has(day)).map((day) => ({
    dayOfWeek: day,
    dayLabel: DAY_LABELS[day] ?? `Day ${day}`,
    deals: dealsByDay.get(day) ?? [],
  }));
}

function weekdaySort(a: number, b: number): number {
  return (
    WEEKDAY_UI_ORDER.indexOf(a as (typeof WEEKDAY_UI_ORDER)[number]) -
    WEEKDAY_UI_ORDER.indexOf(b as (typeof WEEKDAY_UI_ORDER)[number])
  );
}

function areConsecutiveWeekdays(first: number, second: number): boolean {
  const firstIndex = WEEKDAY_UI_ORDER.indexOf(
    first as (typeof WEEKDAY_UI_ORDER)[number],
  );
  const secondIndex = WEEKDAY_UI_ORDER.indexOf(
    second as (typeof WEEKDAY_UI_ORDER)[number],
  );
  return firstIndex >= 0 && secondIndex === firstIndex + 1;
}

function formatDayRange(start: number, end: number): string {
  if (start === end) {
    return DAY_ABBREVIATIONS[start] ?? `Day ${start}`;
  }
  const startLabel = DAY_ABBREVIATIONS[start] ?? `Day ${start}`;
  const endLabel = DAY_ABBREVIATIONS[end] ?? `Day ${end}`;
  return `${startLabel}-${endLabel}`;
}

function compressDayRanges(days: number[]): string[] {
  const sorted = [...days].sort(weekdaySort);
  if (sorted.length === 0) {
    return [];
  }

  const ranges: string[] = [];
  let rangeStart = sorted[0];
  let rangeEnd = sorted[0];

  for (const day of sorted.slice(1)) {
    if (areConsecutiveWeekdays(rangeEnd, day)) {
      rangeEnd = day;
    } else {
      ranges.push(formatDayRange(rangeStart, rangeEnd));
      rangeStart = day;
      rangeEnd = day;
    }
  }

  ranges.push(formatDayRange(rangeStart, rangeEnd));
  return ranges;
}

export function formatDealDayBadge(schedules: ScheduleSlice[]): string {
  if (schedules.length === 0) {
    return "—";
  }

  const days = [...new Set(schedules.map((schedule) => schedule.dayOfWeek))];
  if (days.length === ALL_WEEKDAYS.length) {
    return "7 Days";
  }

  return compressDayRanges(days).join(", ");
}

function formatCompactMinute(minute: number, includeMeridiem: boolean): string {
  const normalizedMinute = minutesWithinDay(minute);
  const hours24 = Math.floor(normalizedMinute / 60);
  const minutes = normalizedMinute % 60;
  const suffix = hours24 >= 12 ? "pm" : "am";
  const hours12 = hours24 % 12 || 12;
  const time =
    minutes === 0
      ? `${hours12}`
      : `${hours12}:${minutes.toString().padStart(2, "0")}`;

  return includeMeridiem ? `${time}${suffix}` : time;
}

export function formatCompactTimeRange(startMinute: number, endMinute: number): string {
  const normalizedStart = minutesWithinDay(startMinute);
  const normalizedEnd = minutesWithinDay(endMinute);

  if (normalizedStart === 0) {
    return `Until ${formatCompactMinute(normalizedEnd, true)}`;
  }

  if (normalizedEnd === 0) {
    return `From ${formatCompactMinute(startMinute, true)}`;
  }

  const startPeriod = startMinute >= 720 ? "pm" : "am";
  const endPeriod = normalizedEnd >= 720 ? "pm" : "am";
  const start = formatCompactMinute(startMinute, startPeriod !== endPeriod);
  const end = formatCompactMinute(normalizedEnd, true);
  return `${start}-${end}`;
}

export function formatDealTimeBadge(schedules: ScheduleSlice[]): string {
  if (schedules.length === 0) {
    return "—";
  }

  const timeRanges = new Set(
    schedules.map(
      (schedule) => `${schedule.startMinute}-${schedule.endMinute}`,
    ),
  );

  if (timeRanges.size === 1) {
    const schedule = schedules[0];
    if (isAllDaySchedule(schedule.startMinute, schedule.endMinute)) {
      return "";
    }
    return formatCompactTimeRange(schedule.startMinute, schedule.endMinute);
  }

  return "Various";
}

export function formatScheduleSummary(
  schedules: ScheduleSlice[],
): string {
  if (schedules.length === 0) {
    return "Schedule not listed";
  }

  const grouped = new Map<string, number[]>();

  for (const schedule of schedules) {
    const timeRange = isAllDaySchedule(schedule.startMinute, schedule.endMinute)
      ? ""
      : `${formatMinute(schedule.startMinute)}–${formatMinute(schedule.endMinute)}`;
    const days = grouped.get(timeRange) ?? [];
    days.push(schedule.dayOfWeek);
    grouped.set(timeRange, days);
  }

  return Array.from(grouped.entries())
    .map(([timeRange, days]) => {
      const dayNames = days
        .sort((a, b) => a - b)
        .map((day) => DAY_LABELS[day] ?? `Day ${day}`)
        .join(", ");
      return timeRange ? `${dayNames}: ${timeRange}` : dayNames;
    })
    .join(" · ");
}

function formatDisplayDate(isoDate: string): string {
  const [year, month, day] = isoDate.split("-").map(Number);
  const date = new Date(year, month - 1, day);
  return date.toLocaleDateString("en-AU", {
    day: "numeric",
    month: "short",
    year: "numeric",
  });
}

export function formatDealDateRange(
  startDate?: string | null,
  endDate?: string | null,
): string | null {
  if (!startDate && !endDate) {
    return null;
  }

  if (startDate && endDate) {
    if (startDate === endDate) {
      return formatDisplayDate(startDate);
    }
    return `${formatDisplayDate(startDate)} – ${formatDisplayDate(endDate)}`;
  }

  if (startDate) {
    return `From ${formatDisplayDate(startDate)}`;
  }

  return `Until ${formatDisplayDate(endDate!)}`;
}

export function formatDealScheduleLine(
  schedules: ScheduleSlice[],
  startDate?: string | null,
  endDate?: string | null,
): string {
  const parts: string[] = [];
  const datePart = formatDealDateRange(startDate, endDate);

  if (datePart) {
    parts.push(datePart);
  }

  if (schedules.length > 0) {
    const dayPart = formatDealDayBadge(schedules);
    if (dayPart !== "—") {
      parts.push(dayPart);
    }

    const timePart = formatDealTimeBadge(schedules);
    if (timePart && timePart !== "—") {
      parts.push(timePart);
    }
  }

  if (parts.length === 0) {
    return "Schedule not listed";
  }

  return parts.join(" · ");
}
