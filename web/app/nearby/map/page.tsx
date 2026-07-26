import { Suspense } from "react";
import type { Metadata } from "next";
import { permanentRedirect } from "next/navigation";
import { MapPage } from "@/components/MapPage";
import { NEARBY_WHERE_SLUG } from "@/lib/search/slugs";
import { legacyDaysRedirectHref } from "@/lib/search/url";

const title = "Happy Hour Map Nearby | DuskRoute";
const description =
  "Explore pub and bar happy hour deals near you on a map.";
const path = `/${NEARBY_WHERE_SLUG}/map`;

export const metadata: Metadata = {
  title,
  description,
  alternates: {
    canonical: path,
  },
  openGraph: {
    title,
    description,
    type: "website",
    url: path,
  },
};

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
