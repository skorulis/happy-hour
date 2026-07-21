"use client";

import { Trash2 } from "lucide-react";
import { useId, useRef, useState, type ReactNode } from "react";
import {
  DEFAULT_SCHEDULE_DAY,
  DEFAULT_SCHEDULE_END_MINUTE,
  DEFAULT_SCHEDULE_START_MINUTE,
  endMinutesFromTimeInputRelativeToStart,
  minuteToTimeInputValue,
  normalizedEndMinute,
  timeInputValueToMinutes,
} from "@/lib/deal-schedule-edit";
import type { ProcessedDeal, ProcessedDealSchedule } from "@/lib/extract/types";
import {
  DAY_LABELS,
  WEEKDAY_UI_ORDER,
  formatScheduleSummary,
} from "@/lib/search/schedule";

const inputClassName =
  "w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-foreground outline-none ring-accent focus:ring-2";

const compactInputClassName =
  "rounded-lg border border-border bg-surface px-3 py-2 text-sm text-foreground outline-none ring-accent focus:ring-2";

const labelClassName = "text-xs font-medium text-secondary";

type EditableSchedule = ProcessedDealSchedule & { id: number };

type EditDealContentProps = {
  deal: ProcessedDeal;
  onChange: (deal: ProcessedDeal) => void;
};

function todayIsoDate(): string {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function withScheduleIds(schedules: ProcessedDealSchedule[]): EditableSchedule[] {
  return schedules.map((schedule, index) => ({
    ...schedule,
    id: -(index + 1),
  }));
}

function stripScheduleIds(schedules: EditableSchedule[]): ProcessedDealSchedule[] {
  return schedules.map(({ dayOfWeek, startMinute, endMinute }) => ({
    dayOfWeek,
    startMinute,
    endMinute,
  }));
}

function Field({
  label,
  children,
}: {
  label: string;
  children: ReactNode;
}) {
  return (
    <div className="flex flex-col gap-1">
      <span className={labelClassName}>{label}</span>
      {children}
    </div>
  );
}

function OptionalDateRow({
  label,
  value,
  onChange,
}: {
  label: string;
  value: string | null;
  onChange: (next: string | null) => void;
}) {
  return (
    <div className="flex flex-wrap items-center gap-2 text-sm">
      <span className="w-10 text-secondary">{label}</span>
      {value ? (
        <>
          <input
            type="date"
            className={compactInputClassName}
            value={value}
            onChange={(event) => {
              onChange(event.target.value || null);
            }}
          />
          <button
            type="button"
            className="text-sm text-danger hover:underline"
            onClick={() => {
              onChange(null);
            }}
          >
            Clear
          </button>
        </>
      ) : (
        <>
          <span className="text-secondary">Not set</span>
          <button
            type="button"
            className="text-sm text-accent-soft hover:underline"
            onClick={() => {
              onChange(todayIsoDate());
            }}
          >
            Set date
          </button>
        </>
      )}
    </div>
  );
}

export function EditDealContent({ deal, onChange }: EditDealContentProps) {
  const formId = useId();
  const nextScheduleIdRef = useRef(-(deal.schedules.length + 1));
  const [schedules, setSchedules] = useState(() =>
    withScheduleIds(deal.schedules),
  );
  const isDiscarded = deal.status === "rejected";

  function update(partial: Partial<ProcessedDeal>) {
    onChange({ ...deal, ...partial });
  }

  function commitSchedules(next: EditableSchedule[]) {
    setSchedules(next);
    onChange({ ...deal, schedules: stripScheduleIds(next) });
  }

  function updateScheduleAt(
    id: number,
    patch: Partial<ProcessedDealSchedule>,
  ) {
    commitSchedules(
      schedules.map((schedule) =>
        schedule.id === id ? { ...schedule, ...patch } : schedule,
      ),
    );
  }

  function addSchedule() {
    const id = nextScheduleIdRef.current;
    nextScheduleIdRef.current -= 1;
    commitSchedules([
      ...schedules,
      {
        id,
        dayOfWeek: DEFAULT_SCHEDULE_DAY,
        startMinute: DEFAULT_SCHEDULE_START_MINUTE,
        endMinute: DEFAULT_SCHEDULE_END_MINUTE,
      },
    ]);
  }

  function removeSchedule(id: number) {
    commitSchedules(schedules.filter((schedule) => schedule.id !== id));
  }

  if (isDiscarded) {
    return (
      <div className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-border-subtle bg-surface/90 px-5 py-4">
        <p className="text-sm text-secondary">This deal will not be created</p>
        <button
          type="button"
          className="text-sm font-medium text-accent-soft hover:underline"
          onClick={() => {
            update({ status: "new" });
          }}
        >
          Undo
        </button>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-4 rounded-xl border border-border-subtle bg-surface/90 p-5">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0 flex-1">
          <Field label="Title">
            <input
              id={`${formId}-title`}
              type="text"
              className={inputClassName}
              value={deal.title ?? ""}
              onChange={(event) => {
                update({ title: event.target.value || null });
              }}
              placeholder="Untitled deal"
            />
          </Field>
        </div>
        <button
          type="button"
          className="mt-5 shrink-0 rounded-lg p-2 text-muted transition-colors hover:bg-danger-muted hover:text-danger"
          aria-label="Discard deal"
          title="Discard deal"
          onClick={() => {
            update({ status: "rejected" });
          }}
        >
          <Trash2 className="size-4" aria-hidden />
        </button>
      </div>

      <Field label="Details">
        <textarea
          id={`${formId}-details`}
          className={`${inputClassName} min-h-24 resize-y`}
          value={deal.details ?? ""}
          onChange={(event) => {
            update({ details: event.target.value || null });
          }}
          rows={4}
        />
      </Field>

      <Field label="Conditions">
        <textarea
          id={`${formId}-conditions`}
          className={`${inputClassName} min-h-16 resize-y`}
          value={deal.conditions ?? ""}
          onChange={(event) => {
            update({ conditions: event.target.value || null });
          }}
          rows={2}
        />
      </Field>

      <Field label="Promotion dates">
        <div className="flex flex-col gap-2">
          <OptionalDateRow
            label="Start"
            value={deal.startDate}
            onChange={(startDate) => {
              update({ startDate });
            }}
          />
          <OptionalDateRow
            label="End"
            value={deal.endDate}
            onChange={(endDate) => {
              update({ endDate });
            }}
          />
        </div>
      </Field>

      <Field label="Schedule">
        <div className="flex flex-col gap-2">
          {schedules.length > 0 ? (
            <p className="text-xs text-secondary">
              {formatScheduleSummary(stripScheduleIds(schedules))}
            </p>
          ) : null}

          {schedules.map((schedule) => (
            <div
              key={schedule.id}
              className="flex flex-row flex-nowrap items-center gap-2 overflow-x-auto"
            >
              <select
                aria-label="Day"
                className={`${compactInputClassName} min-w-28 shrink-0`}
                value={schedule.dayOfWeek}
                onChange={(event) => {
                  updateScheduleAt(schedule.id, {
                    dayOfWeek: Number(event.target.value),
                  });
                }}
              >
                {WEEKDAY_UI_ORDER.map((day) => (
                  <option key={day} value={day}>
                    {DAY_LABELS[day]}
                  </option>
                ))}
              </select>

              <input
                type="time"
                aria-label="Start time"
                className={`${compactInputClassName} shrink-0`}
                value={minuteToTimeInputValue(schedule.startMinute)}
                onChange={(event) => {
                  const startMinute = timeInputValueToMinutes(
                    event.target.value,
                  );
                  updateScheduleAt(schedule.id, {
                    startMinute,
                    endMinute: normalizedEndMinute(
                      schedule.endMinute,
                      startMinute,
                    ),
                  });
                }}
              />

              <span className="shrink-0 text-secondary">–</span>

              <input
                type="time"
                aria-label="End time"
                className={`${compactInputClassName} shrink-0`}
                value={minuteToTimeInputValue(schedule.endMinute)}
                onChange={(event) => {
                  updateScheduleAt(schedule.id, {
                    endMinute: endMinutesFromTimeInputRelativeToStart(
                      event.target.value,
                      schedule.startMinute,
                    ),
                  });
                }}
              />

              <button
                type="button"
                className="shrink-0 text-sm text-danger hover:underline"
                onClick={() => {
                  removeSchedule(schedule.id);
                }}
              >
                Remove
              </button>
            </div>
          ))}

          <button
            type="button"
            className="self-start text-sm text-accent-soft hover:underline"
            onClick={addSchedule}
          >
            Add schedule time
          </button>
        </div>
      </Field>
    </div>
  );
}
