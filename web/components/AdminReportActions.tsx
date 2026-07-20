"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

const approveButtonClassName =
  "rounded-lg bg-accent px-3 py-1.5 text-sm font-medium text-accent-fg transition-colors hover:bg-accent-hover disabled:cursor-not-allowed disabled:opacity-60";

const rejectButtonClassName =
  "rounded-lg border border-border bg-surface px-3 py-1.5 text-sm font-medium text-secondary transition-colors hover:bg-surface-elevated hover:text-foreground disabled:cursor-not-allowed disabled:opacity-60";

type AdminReportActionsProps = {
  reportId: number;
};

export function AdminReportActions({ reportId }: AdminReportActionsProps) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleAction(action: "approve" | "reject") {
    setLoading(true);
    setError(null);

    try {
      const response = await fetch(`/api/reports/${reportId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action }),
      });

      if (!response.ok) {
        const data = (await response.json().catch(() => null)) as {
          error?: string;
        } | null;
        setError(data?.error ?? "Something went wrong");
        return;
      }

      router.refresh();
    } catch {
      setError("Something went wrong");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex shrink-0 flex-col items-end gap-2">
      <div className="flex gap-2">
        <button
          type="button"
          className={approveButtonClassName}
          disabled={loading}
          onClick={() => handleAction("approve")}
        >
          Approve
        </button>
        <button
          type="button"
          className={rejectButtonClassName}
          disabled={loading}
          onClick={() => handleAction("reject")}
        >
          Reject
        </button>
      </div>
      {error ? <p className="text-xs text-danger">{error}</p> : null}
    </div>
  );
}
