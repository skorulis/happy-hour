import { CalendarDays, Clock } from "lucide-react";

type DealScheduleLineProps = {
  text: string;
  className?: string;
};

function scheduleIconForText(text: string) {
  return /^(From|Until|\d)/.test(text) ? CalendarDays : Clock;
}

export function DealScheduleLine({ text, className = "" }: DealScheduleLineProps) {
  const Icon = scheduleIconForText(text);

  return (
    <span
      className={`inline-flex min-w-0 items-center gap-1.5 text-sm text-zinc-500 dark:text-zinc-400 ${className}`}
    >
      <Icon
        aria-hidden
        className="h-3.5 w-3.5 shrink-0"
        strokeWidth={1.75}
      />
      <span className="min-w-0">{text}</span>
    </span>
  );
}
