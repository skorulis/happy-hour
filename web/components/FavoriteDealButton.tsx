"use client";

import { Heart } from "lucide-react";

type FavoriteDealButtonProps = {
  isFavorited: boolean;
  onToggle: () => void;
};

export function FavoriteDealButton({
  isFavorited,
  onToggle,
}: FavoriteDealButtonProps) {
  return (
    <button
      type="button"
      onClick={onToggle}
      aria-pressed={isFavorited}
      aria-label={
        isFavorited ? "Remove from favourites" : "Add to favourites"
      }
      className="inline-flex shrink-0 items-center justify-center rounded-full border border-zinc-300 p-2 text-zinc-500 transition-colors hover:border-amber-500 hover:bg-amber-50 hover:text-amber-700 dark:border-zinc-600 dark:text-zinc-400 dark:hover:border-amber-500 dark:hover:bg-amber-950/30 dark:hover:text-amber-400"
    >
      <Heart
        aria-hidden
        className={`h-4 w-4 ${isFavorited ? "fill-amber-600 text-amber-600 dark:fill-amber-400 dark:text-amber-400" : ""}`}
        strokeWidth={1.75}
      />
    </button>
  );
}
