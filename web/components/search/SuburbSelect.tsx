"use client";

import { MapPin } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import type { SuburbSearchResult } from "@/lib/search/queries";

export type WhereFilter =
  | { kind: "anywhere" }
  | { kind: "suburb"; id: number; suburb: SuburbSearchResult }
  | { kind: "nearMe"; lat: number; lng: number };

type SuburbSelectPanelProps = {
  where: WhereFilter;
  onChange: (where: WhereFilter) => void;
  onClose: () => void;
  open: boolean;
};

function formatSuburbLabel(suburb: SuburbSearchResult): string {
  return suburb.postcode ? `${suburb.name} (${suburb.postcode})` : suburb.name;
}

export function formatWhereLabel(where: WhereFilter): string {
  if (where.kind === "suburb") {
    return formatSuburbLabel(where.suburb);
  }
  if (where.kind === "nearMe") {
    return "Near me";
  }
  return "Anywhere";
}

export function SuburbSelectPanel({
  where,
  onChange,
  onClose,
  open,
}: SuburbSelectPanelProps) {
  const [query, setQuery] = useState("");
  const [suburbs, setSuburbs] = useState<SuburbSearchResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [locating, setLocating] = useState(false);
  const [locationError, setLocationError] = useState<string | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const selectedSuburbId = where.kind === "suburb" ? where.id : null;

  useEffect(() => {
    if (!open) {
      return;
    }

    inputRef.current?.focus();
  }, [open]);

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

  function handleSelect(suburb: SuburbSearchResult) {
    onChange({ kind: "suburb", id: suburb.id, suburb });
    onClose();
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
        onClose();
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

  return (
    <div className="w-80 max-w-[calc(100vw-3rem)] rounded-xl border border-zinc-200 bg-white p-3 shadow-lg dark:border-zinc-700 dark:bg-zinc-900">
      <input
        ref={inputRef}
        type="search"
        value={query}
        onChange={(event) => setQuery(event.target.value)}
        placeholder="Search suburbs..."
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
        <MapPin aria-hidden className="h-4 w-4 shrink-0" />
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
  );
}
