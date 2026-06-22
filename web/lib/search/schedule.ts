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
  if (days.length === 0 || days.length === ALL_WEEKDAYS.length) {
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

/** Matches DealDay.calendarWeekday in the Swift app (1 = Sunday … 7 = Saturday). */
export function currentCalendarWeekday(date = new Date()): number {
  return date.getDay() + 1;
}

export function currentMinuteOfDay(date = new Date()): number {
  return date.getHours() * 60 + date.getMinutes();
}

export function formatMinute(minute: number): string {
  const hours24 = Math.floor(minute / 60);
  const minutes = minute % 60;
  const suffix = hours24 >= 12 ? "pm" : "am";
  const hours12 = hours24 % 12 || 12;
  return `${hours12}:${minutes.toString().padStart(2, "0")}${suffix}`;
}

export function formatScheduleSummary(
  schedules: Array<{
    dayOfWeek: number;
    startMinute: number;
    endMinute: number;
  }>,
): string {
  if (schedules.length === 0) {
    return "Schedule not listed";
  }

  const grouped = new Map<string, number[]>();

  for (const schedule of schedules) {
    const timeRange = `${formatMinute(schedule.startMinute)}–${formatMinute(schedule.endMinute)}`;
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
      return `${dayNames}: ${timeRange}`;
    })
    .join(" · ");
}
