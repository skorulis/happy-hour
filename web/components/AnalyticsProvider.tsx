"use client";

import { track } from "@/lib/analytics/client";
import { usePathname, useSearchParams } from "next/navigation";
import { Suspense, useEffect, useRef } from "react";

function AnalyticsPageViews() {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const lastKeyRef = useRef<string | null>(null);

  useEffect(() => {
    const search = searchParams.toString();
    const key = `${pathname}?${search}`;
    if (lastKeyRef.current === key) {
      return;
    }
    lastKeyRef.current = key;

    track("page_viewed", {
      path: pathname,
      search: search.length > 0 ? `?${search}` : "",
    });
  }, [pathname, searchParams]);

  return null;
}

export function AnalyticsProvider({ children }: { children: React.ReactNode }) {
  return (
    <>
      <Suspense fallback={null}>
        <AnalyticsPageViews />
      </Suspense>
      {children}
    </>
  );
}
