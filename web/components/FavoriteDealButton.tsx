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
      className="inline-flex shrink-0 items-center justify-center rounded-full border border-border p-2 text-muted transition-colors hover:border-accent hover:bg-accent-muted hover:text-accent-soft"
    >
      <Heart
        aria-hidden
        className={`h-4 w-4 ${isFavorited ? "fill-accent text-accent-soft" : ""}`}
        strokeWidth={1.75}
      />
    </button>
  );
}
