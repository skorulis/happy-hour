"use client";

import { track } from "@/lib/analytics/client";
import { navIconPillClassName } from "@/lib/navStyles";
import {
  listHrefFromMapEntry,
  mapEntryFromListPathname,
  readMapEntry,
  writeMapEntry,
} from "@/lib/search/map-entry";
import { parseWherePath, pathnameToMapHref } from "@/lib/search/url";
import { List, MapPin } from "lucide-react";
import Link from "next/link";
import { usePathname, useSearchParams } from "next/navigation";
import { useEffect, useState } from "react";

export function MapNavLink() {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const isMapOpen = pathname === "/map" || pathname.endsWith("/map");
  const mapHref = pathnameToMapHref(pathname, searchParams);
  const [href, setHref] = useState(() =>
    isMapOpen ? listHrefFromMapEntry(null, searchParams) : mapHref,
  );
  const label = isMapOpen ? "List" : "Map";
  const Icon = isMapOpen ? List : MapPin;

  useEffect(() => {
    if (isMapOpen) {
      setHref(listHrefFromMapEntry(readMapEntry(), searchParams));
      return;
    }
    setHref(pathnameToMapHref(pathname, searchParams));
  }, [isMapOpen, pathname, searchParams]);

  function handleClick() {
    if (!isMapOpen) {
      writeMapEntry(mapEntryFromListPathname(pathname));
    }

    const where = parseWherePath(pathname);
    track("view_mode_toggled", {
      from: isMapOpen ? "map" : "list",
      to: isMapOpen ? "list" : "map",
      where_kind: where.kind,
    });
  }

  return (
    <Link
      href={href}
      aria-label={label}
      className={navIconPillClassName(false)}
      onClick={handleClick}
    >
      <Icon aria-hidden className="h-4 w-4" strokeWidth={1.75} />
      <span className="hidden md:inline" aria-hidden>
        {label}
      </span>
    </Link>
  );
}
