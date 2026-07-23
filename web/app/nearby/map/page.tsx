import { Suspense } from "react";
import { permanentRedirect } from "next/navigation";
import { MapPage } from "@/components/MapPage";
import { legacyDaysRedirectHref } from "@/lib/search/url";

type NearbyMapPageProps = {
  searchParams: Promise<{ days?: string; q?: string }>;
};

export default async function NearbyMapPage({
  searchParams,
}: NearbyMapPageProps) {
  const resolved = await searchParams;
  const search = new URLSearchParams();
  if (resolved.days) {
    search.set("days", resolved.days);
  }
  if (resolved.q) {
    search.set("q", resolved.q);
  }

  const daysRedirect = legacyDaysRedirectHref("/nearby/map", search);
  if (daysRedirect) {
    permanentRedirect(daysRedirect);
  }

  return (
    <Suspense
      fallback={
        <div className="relative flex min-h-0 flex-1 flex-col">
          <div className="absolute inset-0 flex items-center justify-center bg-background text-sm text-muted">
            Loading map...
          </div>
        </div>
      }
    >
      <MapPage initialWhere={{ kind: "nearMe" }} />
    </Suspense>
  );
}
