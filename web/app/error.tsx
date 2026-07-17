"use client";

import * as Sentry from "@sentry/nextjs";
import { useEffect } from "react";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    Sentry.captureException(error);
  }, [error]);

  return (
    <div className="flex flex-1 flex-col items-center justify-center gap-4 px-6 py-16 text-center">
      <div
        className="flex h-12 w-12 items-center justify-center rounded-full border border-border text-2xl text-muted"
        aria-hidden
      >
        !
      </div>
      <h1 className="text-2xl font-semibold tracking-tight text-foreground">
        This page couldn&apos;t load
      </h1>
      <p className="max-w-sm text-sm text-muted">
        Reload to try again, or go back.
      </p>
      <div className="mt-2 flex gap-3">
        <button
          type="button"
          onClick={reset}
          className="rounded-lg bg-foreground px-4 py-2 text-sm font-medium text-background"
        >
          Reload
        </button>
        <button
          type="button"
          onClick={() => window.history.back()}
          className="rounded-lg border border-border bg-surface px-4 py-2 text-sm font-medium text-foreground"
        >
          Back
        </button>
      </div>
    </div>
  );
}
