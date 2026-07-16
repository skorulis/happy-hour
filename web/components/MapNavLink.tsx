"use client";

import { navIconPillClassName } from "@/lib/navStyles";
import {
  pathnameToListHref,
  pathnameToMapHref,
} from "@/lib/search/url";
import { List, MapPin } from "lucide-react";
import Link from "next/link";
import { usePathname, useSearchParams } from "next/navigation";

export function MapNavLink() {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const isMapOpen = pathname === "/map" || pathname.endsWith("/map");
  const href = isMapOpen
    ? pathnameToListHref(pathname, searchParams)
    : pathnameToMapHref(pathname, searchParams);
  const label = isMapOpen ? "List" : "Map";
  const Icon = isMapOpen ? List : MapPin;

  return (
    <Link
      href={href}
      aria-label={label}
      className={navIconPillClassName(false)}
    >
      <Icon aria-hidden className="h-4 w-4" strokeWidth={1.75} />
      <span className="hidden md:inline" aria-hidden>
        {label}
      </span>
    </Link>
  );
}
