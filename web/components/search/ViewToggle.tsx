"use client";

import type { SearchViewMode } from "@/lib/search/url";

type ViewToggleProps = {
  view: SearchViewMode;
  onChange: (view: SearchViewMode) => void;
};

const OPTIONS: { value: SearchViewMode; label: string }[] = [
  { value: "list", label: "List" },
  { value: "map", label: "Map" },
];

export function ViewToggle({ view, onChange }: ViewToggleProps) {
  return (
    <div
      className="inline-flex rounded-full border border-zinc-300 bg-white p-0.5 dark:border-zinc-600 dark:bg-zinc-950"
      role="group"
      aria-label="Results view"
    >
      {OPTIONS.map((option) => {
        const isActive = view === option.value;

        return (
          <button
            key={option.value}
            type="button"
            onClick={() => onChange(option.value)}
            aria-pressed={isActive}
            className={`rounded-full px-3 py-1 text-xs font-semibold transition-colors ${
              isActive
                ? "bg-amber-600 text-white dark:bg-amber-500"
                : "text-zinc-600 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-zinc-100"
            }`}
          >
            {option.label}
          </button>
        );
      })}
    </div>
  );
}
