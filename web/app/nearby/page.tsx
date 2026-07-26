import { Suspense } from "react";
import type { Metadata } from "next";
import { permanentRedirect } from "next/navigation";
import { SearchPage } from "@/components/SearchPage";
import { formatNearbyDealsTitle } from "@/lib/search/schedule";
import { NEARBY_WHERE_SLUG } from "@/lib/search/slugs";
import { legacyDaysRedirectHref } from "@/lib/search/url";

const title = formatNearbyDealsTitle([], []);
const description = "Find pub and bar happy hour deals near you.";
const path = `/${NEARBY_WHERE_SLUG}`;

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

type NearbyPageProps = {
  searchParams: Promise<{ days?: string; q?: string }>;
};

export default async function NearbyPage({ searchParams }: NearbyPageProps) {
  const resolved = await searchParams;
  const search = new URLSearchParams();
  if (resolved.days) {
    search.set("days", resolved.days);
  }
  if (resolved.q) {
    search.set("q", resolved.q);
  }

  const daysRedirect = legacyDaysRedirectHref("/nearby", search);
  if (daysRedirect) {
    permanentRedirect(daysRedirect);
  }

  return (
    <Suspense
      fallback={
        <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-4 py-10 md:px-6">
          <header>
            <h1 className="text-3xl font-bold text-foreground">
              Pub Specials near you
            </h1>
          </header>
        </div>
      }
    >
      <SearchPage initialWhere={{ kind: "nearMe" }} />
    </Suspense>
  );
}
