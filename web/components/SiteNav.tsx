"use client";

import { Suspense } from "react";
import { HomeNavLink } from "@/components/HomeNavLink";
import { MapNavLink } from "@/components/MapNavLink";
import { useFavorites } from "@/lib/favorites/useFavorites";
import { Heart } from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";

function NavLinkFallback({ label }: { label: string }) {
  return (
    <span className="inline-flex items-center gap-1.5 rounded-full border border-zinc-300 px-3 py-1.5 text-sm font-medium text-zinc-600 dark:border-zinc-600 dark:text-zinc-400">
      {label}
    </span>
  );
}

export function SiteNav() {
  const pathname = usePathname();
  const { favoriteIds } = useFavorites();
  const isFavouritesActive = pathname === "/favourites";
  const favouriteCount = favoriteIds.length;
  const favouritesLabel =
    favouriteCount > 0 ? `Favourites (${favouriteCount})` : "Favourites";

  return (
    <header className="border-b border-zinc-200 dark:border-zinc-800">
      <div className="mx-auto flex max-w-4xl items-center justify-between px-6 py-4">
        <Suspense fallback={<NavLinkFallback label="Happy Hours" />}>
          <HomeNavLink />
        </Suspense>
        <div className="flex items-center gap-2">
          <Suspense fallback={<NavLinkFallback label="Map" />}>
            <MapNavLink />
          </Suspense>
          <Link
            href="/favourites"
            aria-current={isFavouritesActive ? "page" : undefined}
            className={`inline-flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-sm font-medium transition-colors ${
              isFavouritesActive
                ? "border-amber-600 bg-amber-600 text-white dark:border-amber-500 dark:bg-amber-500"
                : "border-zinc-300 text-zinc-600 hover:border-amber-500 hover:bg-amber-50 hover:text-amber-700 dark:border-zinc-600 dark:text-zinc-400 dark:hover:border-amber-500 dark:hover:bg-amber-950/30 dark:hover:text-amber-400"
            }`}
          >
            <Heart
              aria-hidden
              className={`h-4 w-4 ${isFavouritesActive ? "fill-white" : ""}`}
              strokeWidth={1.75}
            />
            {favouritesLabel}
          </Link>
        </div>
      </div>
    </header>
  );
}
