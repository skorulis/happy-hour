"use client";

import { navIconPillClassName } from "@/lib/navStyles";
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
      aria-label="Map"
      aria-current={isMapActive ? "page" : undefined}
      className={navIconPillClassName(isMapActive)}
    >
      <MapPin aria-hidden className="h-4 w-4" strokeWidth={1.75} />
      <span className="hidden md:inline" aria-hidden>
        Map
      </span>
    </Link>
  );
}
