import { Suspense } from "react";
import { notFound, permanentRedirect, redirect } from "next/navigation";
import type { Metadata } from "next";
import { SearchPage } from "@/components/SearchPage";
import { SearchUrlRedirect } from "@/components/SearchUrlRedirect";
import { stripDaySuffix } from "@/lib/search/day-path";
import {
  findRegionBySlug,
  findSuburbByWhereSlug,
  listPopularSuburbs,
  searchDealsForSuburb,
} from "@/lib/search/queries";
import {
  formatNearbyDealsTitle,
  formatSuburbDealsMetadataTitle,
} from "@/lib/search/schedule";
import {
  NEARBY_WHERE_SLUG,
  regionAllSuburbsPath,
  regionPath,
  suburbWherePath,
  suburbWhereRedirectPath,
} from "@/lib/search/slugs";
import { legacyDaysRedirectHref, parseWhatTokens } from "@/lib/search/url";

const SUBURB_SSR_DEAL_LIMIT = 200;

type SuburbSearchPageProps = {
  params: Promise<{ suburb: string }>;
  searchParams: Promise<{ days?: string; q?: string }>;
};

export async function generateMetadata({
  params,
  searchParams,
}: SuburbSearchPageProps): Promise<Metadata> {
  const { suburb: rawWhereSlug } = await params;
  const { q: whatParam } = await searchParams;
  const { base: whereSlug, day } = stripDaySuffix(rawWhereSlug);
  const days = day !== null ? [day] : [];
  const what = whatParam ? parseWhatTokens(whatParam) : [];

  if (whereSlug === NEARBY_WHERE_SLUG) {
    const title = formatNearbyDealsTitle(days, what);
    return {
      title,
      description: "Find pub and bar happy hour deals near you.",
      alternates: {
        canonical: `/${NEARBY_WHERE_SLUG}`,
      },
    };
  }

  if (whereSlug === "map") {
    return {};
  }

  const suburb = await findSuburbByWhereSlug(whereSlug);
  if (suburb) {
    const title = formatSuburbDealsMetadataTitle(suburb.name, days, what);
    const description = `Find pub and bar happy hour deals in ${suburb.name}${suburb.postcode ? ` (${suburb.postcode})` : ""}.`;
    const ogImages = suburb.heroImage ? [{ url: suburb.heroImage }] : undefined;

    return {
      title,
      description,
      alternates: {
        canonical: suburbWherePath(suburb.name, suburb.postcode),
      },
      openGraph: {
        title,
        description,
        ...(ogImages ? { images: ogImages } : {}),
      },
      twitter: {
        card: ogImages ? "summary_large_image" : "summary",
        title,
        description,
        ...(ogImages ? { images: ogImages.map((image) => image.url) } : {}),
      },
    };
  }

  const region = await findRegionBySlug(whereSlug);
  if (!region) {
    return {};
  }

  const title = `Pub Specials in ${region.name}`;
  const description = `Find pub and bar happy hour deals in ${region.name}.`;

  return {
    title,
    description,
    alternates: {
      canonical: regionPath(region.name),
    },
    openGraph: {
      title,
      description,
    },
    twitter: {
      card: "summary",
      title,
      description,
    },
  };
}

export default async function SuburbSearchPage({
  params,
  searchParams,
}: SuburbSearchPageProps) {
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

  const daysRedirect = legacyDaysRedirectHref(`/${rawWhereSlug}`, search);
  if (daysRedirect) {
    permanentRedirect(daysRedirect);
  }

  // Exact `/nearby` is a dedicated route; day-suffixed nearby lands here.
  if (whereSlug === NEARBY_WHERE_SLUG && pathDay === null) {
    notFound();
  }

  const redirectPath = suburbWhereRedirectPath(whereSlug, {
    day: pathDay ?? undefined,
    q: whatParam,
  });
  if (redirectPath) {
    redirect(redirectPath);
  }

  const days = pathDay !== null ? [pathDay] : [];
  const what = whatParam ? parseWhatTokens(whatParam) : [];

  if (whereSlug === NEARBY_WHERE_SLUG) {
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
        <SearchPage
          initialWhere={{ kind: "nearMe" }}
          initialDays={days}
          initialWhat={what}
        />
      </Suspense>
    );
  }

  if (whereSlug === "map") {
    // Legacy `/map-{day}` — canonicalize to `/map` so Google Maps referrer checks pass.
    const cleaned = new URLSearchParams();
    if (whatParam) {
      cleaned.set("q", whatParam);
    }
    const qs = cleaned.toString();
    permanentRedirect(qs ? `/map?${qs}` : "/map");
  }

  const suburb = await findSuburbByWhereSlug(whereSlug);
  if (suburb) {
    const {
      deals: initialDeals,
      nearbyDeals: initialNearbyDeals,
      venuesWithoutApplicableDeals: initialVenuesWithoutApplicableDeals,
    } = await searchDealsForSuburb({
      suburbId: suburb.id,
      ...(days.length > 0 ? { days } : {}),
      ...(what.length > 0 ? { query: what.join(",") } : {}),
      limit: SUBURB_SSR_DEAL_LIMIT,
    });

    const initialWhere = {
      kind: "suburb" as const,
      id: suburb.id,
      suburb,
    };

    return (
      <SearchPage
        key={suburb.id}
        initialWhere={initialWhere}
        initialDays={days}
        initialWhat={what}
        initialDeals={initialDeals}
        initialNearbyDeals={initialNearbyDeals}
        initialVenuesWithoutApplicableDeals={
          initialVenuesWithoutApplicableDeals
        }
      />
    );
  }

  const region = await findRegionBySlug(whereSlug);
  if (!region) {
    notFound();
  }

  const popularSuburbs = await listPopularSuburbs(20, {
    regionId: region.id,
    ...(days.length > 0 ? { days } : {}),
    ...(what.length > 0 ? { query: what.join(",") } : {}),
  });

  return (
    <>
      <Suspense fallback={null}>
        <SearchUrlRedirect />
      </Suspense>
      <SearchPage
        key={region.id}
        popularSuburbs={popularSuburbs}
        initialDays={days}
        initialWhat={what}
        pageTitle={`Pub Specials in ${region.name}`}
        listBasePath={regionPath(region.name)}
        regionId={region.id}
        regionName={region.name}
        allSuburbsHref={regionAllSuburbsPath(region.name)}
      />
    </>
  );
}
