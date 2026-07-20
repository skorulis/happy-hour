"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

const cancelButtonClassName =
  "rounded-lg border border-border bg-surface px-3 py-1.5 text-sm font-medium text-secondary transition-colors hover:bg-surface-elevated hover:text-foreground disabled:cursor-not-allowed disabled:opacity-60";

type CancelReportButtonProps = {
  reportId: number;
};

export function CancelReportButton({ reportId }: CancelReportButtonProps) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleCancel() {
    setLoading(true);
    setError(null);

    try {
      const response = await fetch(`/api/reports/${reportId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "reject" }),
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
      <button
        type="button"
        className={cancelButtonClassName}
        disabled={loading}
        onClick={() => void handleCancel()}
      >
        Cancel
      </button>
      {error ? <p className="text-xs text-danger">{error}</p> : null}
    </div>
  );
}
