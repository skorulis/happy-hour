"use client";

import { MapPin } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import type { SuburbSearchResult } from "@/lib/search/queries";

export type WhereFilter =
  | { kind: "anywhere" }
  | { kind: "suburb"; id: number; suburb: SuburbSearchResult }
  | { kind: "nearMe"; lat?: number; lng?: number };

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
  }

  function handleNearMe() {
    onChange({ kind: "nearMe" });
    onClose();
    setQuery("");
  }

  return (
    <div className="w-80 max-w-[calc(100vw-3rem)] rounded-xl border border-border bg-surface-elevated p-3 shadow-card">
      <input
        ref={inputRef}
        type="search"
        value={query}
        onChange={(event) => setQuery(event.target.value)}
        placeholder="Search suburbs..."
        className="mb-2 w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-foreground outline-none ring-accent focus:ring-2"
      />
      <button
        type="button"
        onClick={handleNearMe}
        className={`mb-2 flex w-full items-center gap-2 rounded-lg px-2 py-2 text-left text-sm hover:bg-surface-muted ${
          where.kind === "nearMe"
            ? "font-medium text-accent-soft"
            : "text-secondary"
        }`}
      >
        <MapPin aria-hidden className="h-4 w-4 shrink-0" />
        Near me
      </button>
      <div className="max-h-48 overflow-y-auto">
        {loading ? (
          <p className="px-2 py-2 text-sm text-muted">Loading...</p>
        ) : suburbs.length === 0 ? (
          <p className="px-2 py-2 text-sm text-muted">No suburbs found.</p>
        ) : (
          suburbs.map((suburb) => (
            <button
              key={suburb.id}
              type="button"
              onClick={() => handleSelect(suburb)}
              className={`block w-full rounded-lg px-2 py-2 text-left text-sm hover:bg-surface-muted ${
                suburb.id === selectedSuburbId
                  ? "font-medium text-accent-soft"
                  : "text-secondary"
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
