"use client";

import { useEffect, useRef, useState } from "react";
import type { SuburbSearchResult } from "@/lib/search/queries";

export type WhereFilter =
  | { kind: "anywhere" }
  | { kind: "suburb"; id: number; suburb: SuburbSearchResult }
  | { kind: "nearMe"; lat: number; lng: number };

type SuburbSelectProps = {
  where: WhereFilter;
  onChange: (where: WhereFilter) => void;
};

function formatSuburbLabel(suburb: SuburbSearchResult): string {
  return suburb.postcode ? `${suburb.name} (${suburb.postcode})` : suburb.name;
}

export function SuburbSelect({ where, onChange }: SuburbSelectProps) {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [suburbs, setSuburbs] = useState<SuburbSearchResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [locating, setLocating] = useState(false);
  const [locationError, setLocationError] = useState<string | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) {
      return;
    }

    const controller = new AbortController();
    const timeout = setTimeout(async () => {
      setLoading(true);
      try {
        const params = new URLSearchParams();
        if (query.trim()) {
          params.set("q", query.trim());
        }
        params.set("limit", "20");

        const response = await fetch(`/api/suburbs?${params.toString()}`, {
          signal: controller.signal,
        });
        if (!response.ok) {
          throw new Error("Failed to load suburbs");
        }
        const data = (await response.json()) as {
          suburbs: SuburbSearchResult[];
        };
        setSuburbs(data.suburbs);
      } catch (fetchError) {
        if ((fetchError as Error).name !== "AbortError") {
          setSuburbs([]);
        }
      } finally {
        setLoading(false);
      }
    }, 250);

    return () => {
      controller.abort();
      clearTimeout(timeout);
    };
  }, [open, query]);

  useEffect(() => {
    if (!open) {
      return;
    }

    function handlePointerDown(event: MouseEvent) {
      if (
        containerRef.current &&
        !containerRef.current.contains(event.target as Node)
      ) {
        setOpen(false);
      }
    }

    document.addEventListener("mousedown", handlePointerDown);
    return () => document.removeEventListener("mousedown", handlePointerDown);
  }, [open]);

  const label =
    where.kind === "suburb"
      ? formatSuburbLabel(where.suburb)
      : where.kind === "nearMe"
        ? "Near me"
        : "Anywhere";
  const hasSelection = where.kind !== "anywhere";
  const selectedSuburbId = where.kind === "suburb" ? where.id : null;

  function handleSelect(suburb: SuburbSearchResult) {
    onChange({ kind: "suburb", id: suburb.id, suburb });
    setOpen(false);
    setQuery("");
    setLocationError(null);
  }

  function handleNearMe() {
    if (!navigator.geolocation) {
      setLocationError("Location is not supported by your browser.");
      return;
    }

    setLocating(true);
    setLocationError(null);

    navigator.geolocation.getCurrentPosition(
      (position) => {
        setLocating(false);
        onChange({
          kind: "nearMe",
          lat: position.coords.latitude,
          lng: position.coords.longitude,
        });
        setOpen(false);
        setQuery("");
      },
      (error) => {
        setLocating(false);
        setLocationError(
          error.code === error.PERMISSION_DENIED
            ? "Location permission denied."
            : "Could not get your location.",
        );
      },
      { enableHighAccuracy: false, timeout: 10000 },
    );
  }

  function handleClear(event: React.MouseEvent) {
    event.stopPropagation();
    onChange({ kind: "anywhere" });
    setQuery("");
    setLocationError(null);
  }

  return (
    <div ref={containerRef} className="relative min-w-0 flex-1">
      <button
        type="button"
        onClick={() => setOpen((current) => !current)}
        className={`inline-flex w-full items-center justify-between gap-2 rounded-full border px-4 py-2 text-sm font-medium transition-colors ${
          hasSelection
            ? "border-amber-600 text-amber-700 dark:border-amber-500 dark:text-amber-400"
            : "border-zinc-300 text-zinc-700 hover:border-amber-500 dark:border-zinc-600 dark:text-zinc-300"
        }`}
      >
        <span className="truncate">{label}</span>
        <span className="flex items-center gap-1">
          {hasSelection ? (
            <span
              role="button"
              tabIndex={0}
              onClick={handleClear}
              onKeyDown={(event) => {
                if (event.key === "Enter" || event.key === " ") {
                  event.preventDefault();
                  onChange({ kind: "anywhere" });
                  setQuery("");
                  setLocationError(null);
                }
              }}
              className="rounded p-0.5 text-zinc-400 hover:bg-zinc-100 hover:text-zinc-600 dark:hover:bg-zinc-800"
              aria-label="Clear suburb"
            >
              <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </span>
          ) : null}
          <svg
            aria-hidden="true"
            className={`h-4 w-4 shrink-0 transition-transform ${open ? "rotate-180" : ""}`}
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
          >
            <path strokeLinecap="round" strokeLinejoin="round" d="M19 9l-7 7-7-7" />
          </svg>
        </span>
      </button>

      {open ? (
        <div className="absolute left-0 z-20 mt-2 w-full min-w-56 rounded-xl border border-zinc-200 bg-white p-3 shadow-lg dark:border-zinc-700 dark:bg-zinc-900">
          <input
            type="search"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Search suburbs..."
            autoFocus
            className="mb-2 w-full rounded-lg border border-zinc-300 bg-white px-3 py-2 text-sm text-zinc-900 outline-none ring-amber-500 focus:ring-2 dark:border-zinc-600 dark:bg-zinc-950 dark:text-zinc-50"
          />
          <button
            type="button"
            onClick={handleNearMe}
            disabled={locating}
            className={`mb-2 flex w-full items-center gap-2 rounded-lg px-2 py-2 text-left text-sm hover:bg-zinc-100 disabled:opacity-60 dark:hover:bg-zinc-800 ${
              where.kind === "nearMe"
                ? "font-medium text-amber-700 dark:text-amber-400"
                : "text-zinc-800 dark:text-zinc-200"
            }`}
          >
            <svg
              aria-hidden="true"
              className="h-4 w-4 shrink-0"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={2}
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M12 11c1.657 0 3-1.343 3-3S13.657 5 12 5 9 6.343 9 8s1.343 3 3 3z"
              />
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M12 22s8-4.5 8-11a8 8 0 10-16 0c0 6.5 8 11 8 11z"
              />
            </svg>
            {locating ? "Getting location..." : "Near me"}
          </button>
          {locationError ? (
            <p className="mb-2 px-2 text-sm text-red-600 dark:text-red-400">
              {locationError}
            </p>
          ) : null}
          <div className="max-h-48 overflow-y-auto">
            {loading ? (
              <p className="px-2 py-2 text-sm text-zinc-500">Loading...</p>
            ) : suburbs.length === 0 ? (
              <p className="px-2 py-2 text-sm text-zinc-500">No suburbs found.</p>
            ) : (
              suburbs.map((suburb) => (
                <button
                  key={suburb.id}
                  type="button"
                  onClick={() => handleSelect(suburb)}
                  className={`block w-full rounded-lg px-2 py-2 text-left text-sm hover:bg-zinc-100 dark:hover:bg-zinc-800 ${
                    suburb.id === selectedSuburbId
                      ? "font-medium text-amber-700 dark:text-amber-400"
                      : "text-zinc-800 dark:text-zinc-200"
                  }`}
                >
                  {formatSuburbLabel(suburb)}
                </button>
              ))
            )}
          </div>
        </div>
      ) : null}
    </div>
  );
}
