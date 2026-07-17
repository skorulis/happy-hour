import { CalendarDays, Clock } from "lucide-react";

type DealScheduleLineProps = {
  text: string;
  className?: string;
};

function usesCalendarIcon(text: string) {
  return /^(From|Until|\d)/.test(text);
}

export function DealScheduleLine({ text, className = "" }: DealScheduleLineProps) {
  const iconProps = {
    "aria-hidden": true as const,
    className: "h-3.5 w-3.5 shrink-0",
    strokeWidth: 1.75,
  };

  return (
    <span
      className={`inline-flex min-w-0 items-center gap-1.5 text-sm text-muted ${className}`}
    >
      {usesCalendarIcon(text) ? (
        <CalendarDays {...iconProps} />
      ) : (
        <Clock {...iconProps} />
      )}
      <span className="min-w-0">{text}</span>
    </span>
  );
}
