"use client";

import { Suspense } from "react";
import { AuthNavLinks } from "@/components/AuthNavLinks";
import { HomeNavLink } from "@/components/HomeNavLink";
import { MapNavLink } from "@/components/MapNavLink";
import { useFavorites } from "@/lib/favorites/useFavorites";
import {
  navFallbackIconClassName,
  navIconPillClassName,
} from "@/lib/navStyles";
import { Heart } from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";

function NavLinkFallback() {
  return <span className={navFallbackIconClassName} aria-hidden />;
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
      <div className="mx-auto flex max-w-4xl items-center justify-between px-4 py-4 md:px-6">
        <Suspense
          fallback={
            <span className="inline-flex h-8 w-8 rounded-full bg-zinc-200 dark:bg-zinc-700" />
          }
        >
          <HomeNavLink />
        </Suspense>
        <div className="flex items-center gap-1.5 md:gap-2">
          <Suspense fallback={<NavLinkFallback />}>
            <MapNavLink />
          </Suspense>
          <Link
            href="/favourites"
            aria-label={favouritesLabel}
            aria-current={isFavouritesActive ? "page" : undefined}
            className={`relative ${navIconPillClassName(isFavouritesActive)}`}
          >
            <Heart
              aria-hidden
              className={`h-4 w-4 ${isFavouritesActive ? "fill-white" : ""}`}
              strokeWidth={1.75}
            />
            {favouriteCount > 0 ? (
              <span
                className={`absolute -right-1 -top-1 flex h-4 min-w-4 items-center justify-center rounded-full px-1 text-[10px] font-semibold leading-none md:hidden ${
                  isFavouritesActive
                    ? "bg-white text-amber-700"
                    : "bg-amber-600 text-white dark:bg-amber-500"
                }`}
                aria-hidden
              >
                {favouriteCount > 99 ? "99+" : favouriteCount}
              </span>
            ) : null}
            <span className="hidden md:inline" aria-hidden>
              {favouritesLabel}
            </span>
          </Link>
          <AuthNavLinks />
        </div>
      </div>
    </header>
  );
}
