"use client";

import { searchParamsToMapHref } from "@/lib/search/url";
import { MapPin } from "lucide-react";
import Link from "next/link";
import { usePathname, useSearchParams } from "next/navigation";

export function MapNavLink() {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const isMapActive = pathname === "/map";
  const href = searchParamsToMapHref(searchParams);

  return (
    <Link
      href={href}
      aria-current={isMapActive ? "page" : undefined}
      className={`inline-flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-sm font-medium transition-colors ${
        isMapActive
          ? "border-amber-600 bg-amber-600 text-white dark:border-amber-500 dark:bg-amber-500"
          : "border-zinc-300 text-zinc-600 hover:border-amber-500 hover:bg-amber-50 hover:text-amber-700 dark:border-zinc-600 dark:text-zinc-400 dark:hover:border-amber-500 dark:hover:bg-amber-950/30 dark:hover:text-amber-400"
      }`}
    >
      <MapPin aria-hidden className="h-4 w-4" strokeWidth={1.75} />
      Map
    </Link>
  );
}
