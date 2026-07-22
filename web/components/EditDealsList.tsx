"use client";

import { useMemo, useState } from "react";
import { EditDealContent } from "@/components/EditDealContent";
import type { EditableVenueDeal } from "@/lib/deals/queries";
import type { EditableDealStatus } from "@/lib/deals/update-deal";
import type { ProcessedDeal } from "@/lib/extract/types";

const saveButtonClassName =
  "rounded-lg bg-accent px-3 py-1.5 text-sm font-medium text-accent-fg transition-colors hover:bg-accent-hover disabled:cursor-not-allowed disabled:opacity-60";

const selectClassName =
  "rounded-lg border border-border bg-surface px-3 py-1.5 text-sm text-foreground outline-none ring-accent focus:ring-2";

function toProcessedDeal(deal: EditableVenueDeal): ProcessedDeal {
  return {
    title: deal.title,
    details: deal.details,
    conditions: deal.conditions,
    creativeURL: null,
    sourceURL: null,
    status: "new",
    startDate: deal.startDate,
    endDate: deal.endDate,
    schedules: deal.schedules,
  };
}

function serializeDraft(
  deal: ProcessedDeal,
  status: EditableDealStatus,
): string {
  return JSON.stringify({
    title: deal.title,
    details: deal.details,
    conditions: deal.conditions,
    startDate: deal.startDate,
    endDate: deal.endDate,
    schedules: deal.schedules,
    status,
  });
}

function EditDealRow({ initialDeal }: { initialDeal: EditableVenueDeal }) {
  const [draft, setDraft] = useState(() => toProcessedDeal(initialDeal));
  const [status, setStatus] = useState<EditableDealStatus>(initialDeal.status);
  const [savedSnapshot, setSavedSnapshot] = useState(() =>
    serializeDraft(toProcessedDeal(initialDeal), initialDeal.status),
  );
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isDirty = useMemo(
    () => serializeDraft(draft, status) !== savedSnapshot,
    [draft, status, savedSnapshot],
  );

  async function handleSave() {
    setSaving(true);
    setError(null);

    try {
      const response = await fetch(`/api/deals/${initialDeal.id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title: draft.title,
          details: draft.details,
          conditions: draft.conditions,
          startDate: draft.startDate,
          endDate: draft.endDate,
          schedules: draft.schedules,
          status,
        }),
      });

      if (!response.ok) {
        const data = (await response.json().catch(() => null)) as {
          error?: string;
        } | null;
        setError(data?.error ?? "Something went wrong");
        return;
      }

      setSavedSnapshot(serializeDraft(draft, status));
    } catch {
      setError("Something went wrong");
    } finally {
      setSaving(false);
    }
  }

  return (
    <li className="space-y-3">
      {initialDeal.imageUrl ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={initialDeal.imageUrl}
          alt=""
          className="h-20 w-20 rounded-lg object-cover"
        />
      ) : null}

      <EditDealContent
        deal={draft}
        onChange={setDraft}
        showDiscard={false}
      />

      <div className="flex flex-wrap items-center justify-between gap-3 px-1">
        <label className="flex items-center gap-2 text-sm text-secondary">
          <span>Status</span>
          <select
            className={selectClassName}
            value={status}
            onChange={(event) => {
              setStatus(event.target.value as EditableDealStatus);
            }}
          >
            <option value="approved">Approved</option>
            <option value="rejected">Rejected</option>
          </select>
        </label>

        <div className="flex flex-col items-end gap-1">
          <button
            type="button"
            className={saveButtonClassName}
            disabled={!isDirty || saving}
            onClick={() => {
              void handleSave();
            }}
          >
            {saving ? "Saving…" : "Save"}
          </button>
          {error ? <p className="text-xs text-danger">{error}</p> : null}
        </div>
      </div>
    </li>
  );
}

export function EditDealsList({
  deals,
}: {
  deals: EditableVenueDeal[];
}) {
  if (deals.length === 0) {
    return (
      <p className="rounded-xl border border-dashed border-border px-4 py-8 text-center text-sm text-muted">
        No deals to edit
      </p>
    );
  }

  return (
    <ul className="flex flex-col gap-8">
      {deals.map((deal) => (
        <EditDealRow key={deal.id} initialDeal={deal} />
      ))}
    </ul>
  );
}
