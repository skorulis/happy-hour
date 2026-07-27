import { Suspense, type ReactNode } from "react";
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { SearchPage } from "@/components/SearchPage";
import { SearchUrlRedirect } from "@/components/SearchUrlRedirect";
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
  regionStatisticsPath,
  suburbWherePath,
} from "@/lib/search/slugs";

const SUBURB_SSR_DEAL_LIMIT = 200;

export async function generateWhereListMetadata(
  whereSlug: string,
  days: number[],
  what: string[],
): Promise<Metadata> {
  if (whereSlug === NEARBY_WHERE_SLUG) {
    const title = formatNearbyDealsTitle(days, what);
    const description = "Find pub and bar happy hour deals near you.";
    const path = `/${NEARBY_WHERE_SLUG}`;
    return {
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
  }

  if (whereSlug === "map") {
    return {};
  }

  const suburb = await findSuburbByWhereSlug(whereSlug);
  if (suburb) {
    const title = formatSuburbDealsMetadataTitle(suburb.name, days, what);
    const description = `Find pub and bar happy hour deals in ${suburb.name}${suburb.postcode ? ` (${suburb.postcode})` : ""}.`;
    const path = suburbWherePath(suburb.name, suburb.postcode);
    const ogImages = suburb.heroImage ? [{ url: suburb.heroImage }] : undefined;

    return {
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
  const path = regionPath(region.name);

  return {
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
    twitter: {
      card: "summary",
      title,
      description,
    },
  };
}

export async function renderWhereListPage(
  whereSlug: string,
  days: number[],
  what: string[],
): Promise<ReactNode> {
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
        statisticsHref={regionStatisticsPath(region.name)}
      />
    </>
  );
}
