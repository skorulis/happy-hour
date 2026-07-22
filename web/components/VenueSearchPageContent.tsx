"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import type { VenueSearchResult } from "@/lib/search/queries";
import { venuePath } from "@/lib/search/slugs";

export function VenueSearchPageContent() {
  const [query, setQuery] = useState("");
  const [venues, setVenues] = useState<VenueSearchResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [hasSearched, setHasSearched] = useState(false);
  const trimmedQuery = query.trim();
  const hasQuery = trimmedQuery.length > 0;

  useEffect(() => {
    if (!hasQuery) {
      return;
    }

    const controller = new AbortController();
    const timeout = setTimeout(async () => {
      setLoading(true);
      setError(null);

      try {
        const params = new URLSearchParams();
        params.set("q", trimmedQuery);
        params.set("limit", "20");

        const response = await fetch(`/api/venues?${params.toString()}`, {
          signal: controller.signal,
        });

        if (!response.ok) {
          throw new Error("Failed to search venues");
        }

        const data = (await response.json()) as { venues: VenueSearchResult[] };
        setVenues(data.venues);
        setHasSearched(true);
      } catch (fetchError) {
        if ((fetchError as Error).name !== "AbortError") {
          setVenues([]);
          setError("Could not search venues.");
        }
      } finally {
        if (!controller.signal.aborted) {
          setLoading(false);
        }
      }
    }, 250);

    return () => {
      controller.abort();
      clearTimeout(timeout);
    };
  }, [hasQuery, trimmedQuery]);

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-4 py-10 md:px-6">
      <header className="space-y-2">
        <h1 className="text-3xl font-bold text-foreground">
          Venue search
        </h1>
      </header>

      <input
        type="search"
        value={query}
        onChange={(event) => setQuery(event.target.value)}
        placeholder="Search venues by name..."
        autoFocus
        className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-foreground outline-none ring-accent focus:ring-2"
      />

      {!hasQuery ? (
        <p className="text-sm text-muted">
          Start typing to search venues.
        </p>
      ) : loading || !hasSearched ? (
        <p className="text-sm text-muted">Searching...</p>
      ) : error ? (
        <p className="text-sm text-danger">{error}</p>
      ) : venues.length === 0 ? (
        <p className="text-sm text-muted">
          No venues found.
        </p>
      ) : (
        <ul className="divide-y divide-border-subtle rounded-xl border border-border">
          {venues.map((venue) => (
            <li key={venue.id}>
              <Link
                href={venuePath(venue.suburbName, venue.name)}
                className="block px-4 py-3 hover:bg-surface-muted"
              >
                <span className="block text-sm font-medium text-foreground">
                  {venue.name}
                </span>
                {venue.suburbName ? (
                  <span className="block text-sm text-muted">
                    {venue.suburbName}
                  </span>
                ) : null}
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
