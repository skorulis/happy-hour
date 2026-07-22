import { Suspense } from "react";
import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { SearchPage } from "@/components/SearchPage";
import { SearchUrlRedirect } from "@/components/SearchUrlRedirect";
import {
  findRegionBySlug,
  findSuburbByWhereSlug,
  listPopularSuburbs,
  searchDealsForSuburb,
} from "@/lib/search/queries";
import { formatSuburbDealsMetadataTitle } from "@/lib/search/schedule";
import {
  NEARBY_WHERE_SLUG,
  regionAllSuburbsPath,
  regionPath,
  suburbWherePath,
} from "@/lib/search/slugs";
import { parseDaysParam, parseWhatTokens } from "@/lib/search/url";

const SUBURB_SSR_DEAL_LIMIT = 200;

type SuburbSearchPageProps = {
  params: Promise<{ suburb: string }>;
  searchParams: Promise<{ days?: string; q?: string }>;
};

export async function generateMetadata({
  params,
  searchParams,
}: SuburbSearchPageProps): Promise<Metadata> {
  const { suburb: whereSlug } = await params;
  const { days: daysParam, q: whatParam } = await searchParams;
  if (whereSlug === NEARBY_WHERE_SLUG) {
    return {};
  }

  const suburb = await findSuburbByWhereSlug(whereSlug);
  if (suburb) {
    const days = parseDaysParam(daysParam ?? null);
    const what = whatParam ? parseWhatTokens(whatParam) : [];
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

  const title = `${region.name} happy hour deals`;
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
  const { suburb: whereSlug } = await params;
  const { days: daysParam, q: whatParam } = await searchParams;

  if (whereSlug === NEARBY_WHERE_SLUG) {
    notFound();
  }

  const days = parseDaysParam(daysParam ?? null);
  const what = whatParam ? parseWhatTokens(whatParam) : [];

  const suburb = await findSuburbByWhereSlug(whereSlug);
  if (suburb) {
    const { deals: initialDeals, nearbyDeals: initialNearbyDeals } =
      await searchDealsForSuburb({
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
        pageTitle={region.name}
        listBasePath={regionPath(region.name)}
        regionId={region.id}
        allSuburbsHref={regionAllSuburbsPath(region.name)}
        includeNearbyLink={false}
      />
    </>
  );
}
