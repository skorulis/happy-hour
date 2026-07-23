"use client";

import { useEffect } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import {
  legacyDaysRedirectHref,
  legacyLocationRedirectHref,
  pathnameToMapHref,
} from "@/lib/search/url";

/**
 * Redirects legacy location query params, `?days=`, and `?view=map` to
 * path-based URLs.
 */
export function SearchUrlRedirect() {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  useEffect(() => {
    const legacyHref = legacyLocationRedirectHref(pathname, searchParams);
    if (legacyHref) {
      router.replace(legacyHref);
      return;
    }

    const daysHref = legacyDaysRedirectHref(pathname, searchParams);
    if (daysHref) {
      router.replace(daysHref);
      return;
    }

    if (searchParams.get("view") !== "map") {
      return;
    }

    router.replace(pathnameToMapHref(pathname, searchParams));
  }, [router, pathname, searchParams]);

  return null;
}
