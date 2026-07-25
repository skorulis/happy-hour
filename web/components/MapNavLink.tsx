"use client";

import { track } from "@/lib/analytics/client";
import { navIconPillClassName } from "@/lib/navStyles";
import {
  getMapEntryVersion,
  listHrefFromMapEntry,
  mapEntryFromListPathname,
  readMapEntry,
  subscribeMapEntry,
  writeMapEntry,
} from "@/lib/search/map-entry";
import {
  parseWhatTokens,
  parseWherePath,
  pathnameToMapHref,
} from "@/lib/search/url";
import { splitWhatForPath } from "@/lib/search/what-path";
import { List, MapPin } from "lucide-react";
import Link from "next/link";
import { usePathname, useSearchParams } from "next/navigation";
import { useSyncExternalStore } from "react";

const subscribeNoop = () => () => {};

export function MapNavLink() {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const parsed = parseWherePath(pathname);
  const isMapOpen = parsed.map;
  // The stored map entry lives in sessionStorage and can only be read on the
  // client, so gate that read behind hydration to keep SSR output stable.
  const isHydrated = useSyncExternalStore(
    subscribeNoop,
    () => true,
    () => false,
  );
  // Re-render when the map entry's day changes while the URL stays `/map`.
  useSyncExternalStore(subscribeMapEntry, getMapEntryVersion, () => 0);
  const href = isMapOpen
    ? listHrefFromMapEntry(
        isHydrated ? readMapEntry() : null,
        searchParams,
        pathname,
      )
    : pathnameToMapHref(pathname, searchParams);
  const label = isMapOpen ? "List" : "Map";
  const Icon = isMapOpen ? List : MapPin;

  function handleClick() {
    if (!isMapOpen) {
      // Catalog what is already encoded on the list pathname; carry the
      // free-text portion of `?q=` onto the map entry so it survives the
      // switch to the map view (where the URL holds no what).
      const { queryTokens } = splitWhatForPath(
        parseWhatTokens(searchParams.get("q") ?? ""),
      );
      writeMapEntry(mapEntryFromListPathname(pathname, queryTokens));
    }

    track("view_mode_toggled", {
      from: isMapOpen ? "map" : "list",
      to: isMapOpen ? "list" : "map",
      where_kind: parsed.kind,
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
