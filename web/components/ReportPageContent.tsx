"use client";

import Link from "next/link";
import { type FormEvent, useState } from "react";
import type { DealReportCategory } from "@/db/schema";
import { dealReportCategories } from "@/lib/reports/categories";

const inputClassName =
  "w-full rounded-lg border border-zinc-300 bg-white px-3 py-2 text-sm text-zinc-900 outline-none ring-amber-500 focus:ring-2 dark:border-zinc-600 dark:bg-zinc-950 dark:text-zinc-50";

const buttonClassName =
  "w-full rounded-lg bg-amber-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-amber-700 disabled:cursor-not-allowed disabled:opacity-60 dark:bg-amber-500 dark:hover:bg-amber-600";

type ReportPageContentProps = {
  dealId: number;
  dealTitle: string;
  venueName: string;
  venuePath: string;
};

export function ReportPageContent({
  dealId,
  dealTitle,
  venueName,
  venuePath,
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
          <h1 className="text-3xl font-bold text-zinc-900 dark:text-zinc-50">
            Thank you for reporting
          </h1>
          <p className="text-sm text-zinc-600 dark:text-zinc-400">
            We&apos;ll review your report and update the deal if needed.
          </p>
        </header>

        <Link href={venuePath} className={buttonClassName}>
          Back to venue
        </Link>
      </div>
    );
  }

  return (
    <div className="mx-auto flex w-full max-w-md flex-col gap-6">
      <header className="space-y-2">
        <h1 className="text-3xl font-bold text-zinc-900 dark:text-zinc-50">
          Report a deal
        </h1>
        <p className="text-sm text-zinc-600 dark:text-zinc-400">
          {dealTitle} at {venueName}
        </p>
      </header>

      <form className="space-y-4" onSubmit={handleSubmit}>
        <div className="space-y-1">
          <label
            htmlFor="category"
            className="block text-sm font-medium text-zinc-700 dark:text-zinc-300"
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
            className="block text-sm font-medium text-zinc-700 dark:text-zinc-300"
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
          <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
        ) : null}

        <button type="submit" disabled={loading} className={buttonClassName}>
          {loading ? "Submitting..." : "Submit"}
        </button>
      </form>
    </div>
  );
}
