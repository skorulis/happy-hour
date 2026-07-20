"use client";

import Link from "next/link";
import { type FormEvent, useState } from "react";
import type { DealReportCategory } from "@/db/schema";
import { dealReportCategories } from "@/lib/reports/categories";

const inputClassName =
  "w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-foreground outline-none ring-accent focus:ring-2";

const buttonClassName =
  "w-full rounded-lg bg-accent px-4 py-2 text-sm font-medium text-accent-fg transition-colors hover:bg-accent-hover disabled:cursor-not-allowed disabled:opacity-60";

const secondaryButtonClassName =
  "w-full rounded-lg border border-border px-4 py-2 text-sm font-medium text-secondary transition-colors hover:bg-surface-muted";

type ReportPageContentProps = {
  dealId: number;
  dealTitle: string;
  venueName: string;
  venuePath: string;
  isLoggedIn: boolean;
};

export function ReportPageContent({
  dealId,
  dealTitle,
  venueName,
  venuePath,
  isLoggedIn,
}: ReportPageContentProps) {
  const [category, setCategory] = useState<DealReportCategory | "">("");
  const [details, setDetails] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);
    setLoading(true);

    try {
      const response = await fetch("/api/reports", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          dealId,
          category,
          details: details.trim() || undefined,
        }),
      });

      if (!response.ok) {
        const payload = (await response.json().catch(() => null)) as {
          error?: string;
        } | null;
        throw new Error(payload?.error ?? "Failed to submit report");
      }

      setSubmitted(true);
    } catch (submitError) {
      setError(
        submitError instanceof Error
          ? submitError.message
          : "Something went wrong. Please try again.",
      );
    } finally {
      setLoading(false);
    }
  }

  if (submitted) {
    return (
      <div className="mx-auto flex w-full max-w-md flex-col gap-6 text-center">
        <header className="space-y-2">
          <h1 className="text-3xl font-bold text-foreground">
            Thank you for reporting
          </h1>
          <p className="text-sm text-secondary">
            We&apos;ll review your report and update the deal if needed.
          </p>
        </header>

        <div className="flex flex-col gap-3">
          <Link href={venuePath} className={buttonClassName}>
            Back to venue
          </Link>
          {isLoggedIn ? (
            <Link href="/profile/reports" className={secondaryButtonClassName}>
              See your reports
            </Link>
          ) : null}
        </div>
      </div>
    );
  }

  return (
    <div className="mx-auto flex w-full max-w-md flex-col gap-6">
      <header className="space-y-2">
        <h1 className="text-3xl font-bold text-foreground">
          Report a deal
        </h1>
        <p className="text-sm text-secondary">
          {dealTitle} at {venueName}
        </p>
      </header>

      <form className="space-y-4" onSubmit={handleSubmit}>
        <div className="space-y-1">
          <label
            htmlFor="category"
            className="block text-sm font-medium text-secondary"
          >
            What&apos;s wrong
          </label>
          <select
            id="category"
            value={category}
            onChange={(event) =>
              setCategory(event.target.value as DealReportCategory | "")
            }
            required
            className={inputClassName}
          >
            <option value="" disabled>
              Select an issue
            </option>
            {dealReportCategories.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </div>

        <div className="space-y-1">
          <label
            htmlFor="details"
            className="block text-sm font-medium text-secondary"
          >
            More information
          </label>
          <textarea
            id="details"
            value={details}
            onChange={(event) => setDetails(event.target.value)}
            rows={4}
            maxLength={2000}
            placeholder="Include any extra details that might help us verify the issue."
            className={inputClassName}
          />
        </div>

        {error ? (
          <p className="text-sm text-danger">{error}</p>
        ) : null}

        <button type="submit" disabled={loading} className={buttonClassName}>
          {loading ? "Submitting..." : "Submit"}
        </button>
      </form>
    </div>
  );
}
