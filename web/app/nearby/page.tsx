import { Suspense } from "react";
import { permanentRedirect } from "next/navigation";
import { SearchPage } from "@/components/SearchPage";
import { legacyDaysRedirectHref } from "@/lib/search/url";

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
