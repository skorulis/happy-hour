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
