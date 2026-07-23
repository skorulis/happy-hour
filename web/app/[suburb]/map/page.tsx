import { Suspense } from "react";
import { notFound, permanentRedirect, redirect } from "next/navigation";
import { MapPage } from "@/components/MapPage";
import { appendDayToPath, stripDaySuffix } from "@/lib/search/day-path";
import { findSuburbByWhereSlug } from "@/lib/search/queries";
import { NEARBY_WHERE_SLUG, suburbMapRedirectPath } from "@/lib/search/slugs";
import { legacyDaysRedirectHref } from "@/lib/search/url";

type SuburbMapPageProps = {
  params: Promise<{ suburb: string }>;
  searchParams: Promise<{ days?: string; q?: string }>;
};

export default async function SuburbMapPage({
  params,
  searchParams,
}: SuburbMapPageProps) {
  const { suburb: rawWhereSlug } = await params;
  const resolvedSearchParams = await searchParams;
  const { days: daysParam, q: whatParam } = resolvedSearchParams;
  const { base: whereSlug, day: pathDay } = stripDaySuffix(rawWhereSlug);

  const search = new URLSearchParams();
  if (daysParam) {
    search.set("days", daysParam);
  }
  if (whatParam) {
    search.set("q", whatParam);
  }

  const daysRedirect = legacyDaysRedirectHref(`/${rawWhereSlug}/map`, search);
  if (daysRedirect) {
    permanentRedirect(daysRedirect);
  }

  if (whereSlug === NEARBY_WHERE_SLUG && pathDay === null) {
    notFound();
  }

  const aliasRedirect = suburbMapRedirectPath(whereSlug);
  if (aliasRedirect) {
    const baseWithoutMap = aliasRedirect.replace(/\/map$/, "");
    const days = pathDay !== null ? [pathDay] : [];
    redirect(`${appendDayToPath(baseWithoutMap, days)}/map`);
  }

  const days = pathDay !== null ? [pathDay] : [];

  if (whereSlug === NEARBY_WHERE_SLUG) {
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
        <MapPage initialWhere={{ kind: "nearMe" }} initialDays={days} />
      </Suspense>
    );
  }

  const suburb = await findSuburbByWhereSlug(whereSlug);
  if (!suburb) {
    notFound();
  }

  const initialWhere = {
    kind: "suburb" as const,
    id: suburb.id,
    suburb,
  };

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
      <MapPage initialWhere={initialWhere} initialDays={days} />
    </Suspense>
  );
}
