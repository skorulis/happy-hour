import Link from "next/link";
import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { RegionFocusNotice } from "@/components/RegionFocusNotice";
import { RegionInfographicPoster } from "@/components/infographic/RegionInfographicPoster";
import { RegionInfographicShare } from "@/components/infographic/RegionInfographicShare";
import { RegionStatisticsView } from "@/components/RegionStatisticsView";
import { composeRegionInfographic } from "@/lib/infographic/compose";
import {
  formatRegionInfographicDescription,
  formatRegionInfographicTitle,
} from "@/lib/infographic/copy";
import {
  loadRegionInfographicFacts,
  loadSuburbInfographicFacts,
} from "@/lib/infographic/load-facts";
import {
  findRegionBySlug,
  findSuburbByWhereSlug,
  type NearbySuburb,
} from "@/lib/search/queries";
import {
  regionPath,
  regionStatisticsPath,
  suburbStatisticsPath,
  suburbWherePath,
} from "@/lib/search/slugs";
import { suburbHeroThumbUrl } from "@/lib/search/venue-hero-url";
import { siteUrl } from "@/lib/site-url";

export const dynamic = "force-dynamic";

function NearbySuburbCard({ suburb }: { suburb: NearbySuburb }) {
  const href = suburbStatisticsPath(suburb.name, suburb.postcode);
  const thumbUrl = suburbHeroThumbUrl(suburb.heroImage);
  return (
    <li>
      <Link
        href={href}
        className="flex items-center gap-3 rounded-lg px-3 py-2.5 transition-colors hover:bg-surface-muted"
      >
        {thumbUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={thumbUrl}
            alt=""
            className="h-14 w-14 shrink-0 rounded-lg object-cover"
          />
        ) : null}
        <span className="min-w-0 flex-1 font-medium text-foreground">{suburb.name}</span>
        <span className="flex shrink-0 flex-col items-end text-sm leading-tight text-muted">
          <span>{suburb.venueCount} {suburb.venueCount === 1 ? "venue" : "venues"}</span>
          <span>{suburb.dealCount} {suburb.dealCount === 1 ? "deal" : "deals"}</span>
        </span>
      </Link>
    </li>
  );
}

type StatisticsPageProps = {
  params: Promise<{ suburb: string }>;
};

export async function generateMetadata({
  params,
}: StatisticsPageProps): Promise<Metadata> {
  const { suburb: slug } = await params;

  const suburb = await findSuburbByWhereSlug(slug);
  if (suburb) {
    const path = suburbStatisticsPath(suburb.name, suburb.postcode);
    const title = formatRegionInfographicTitle(suburb.name);
    const description = `Deal coverage, busiest days, and what's pouring in ${suburb.name}.`;
    const ogImage = `${path}/opengraph-image`;

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
        images: [{ url: ogImage }],
      },
      twitter: {
        card: "summary_large_image",
        title,
        description,
        images: [ogImage],
      },
    };
  }

  const region = await findRegionBySlug(slug);
  if (!region) {
    return {};
  }

  const path = regionStatisticsPath(region.name);
  const title = formatRegionInfographicTitle(region.name);
  const description = `Deal density, busiest days, and what's pouring across ${region.name}.`;
  const ogImage = `${path}/opengraph-image`;

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
      images: [{ url: ogImage }],
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
      images: [ogImage],
    },
  };
}

export default async function StatisticsPage({ params }: StatisticsPageProps) {
  const { suburb: slug } = await params;

  const suburb = await findSuburbByWhereSlug(slug);
  if (suburb) {
    const { facts, nearbySuburbs } = await loadSuburbInfographicFacts({
      suburbId: suburb.id,
      suburbName: suburb.name,
      suburbPostcode: suburb.postcode,
      suburbLat: suburb.lat,
      suburbLng: suburb.lng,
    });

    if (facts.venueCount === 0) {
      return (
        <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-4 px-4 py-10 md:px-6">
          <p className="text-muted">
            This suburb does not have any venues.
            {suburb.regionName && (
              <>
                {" "}
                <Link
                  href={regionStatisticsPath(suburb.regionName)}
                  className="font-medium text-accent-soft underline-offset-2 hover:underline"
                >
                  View {suburb.regionName} statistics
                </Link>
                .
              </>
            )}
          </p>
        </div>
      );
    }

    const composition = composeRegionInfographic(facts, "page");
    const path = suburbStatisticsPath(suburb.name, suburb.postcode);
    const absoluteUrl = `${siteUrl()}${path}`;
    const title = formatRegionInfographicTitle(suburb.name);
    const shareText = formatRegionInfographicDescription(facts);
    const dealsHref = suburbWherePath(suburb.name, suburb.postcode);

    return (
      <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-10 px-4 py-10 md:px-6">
        <RegionInfographicPoster composition={composition} />

        <section className="space-y-3">
          <h2 className="text-sm font-medium tracking-wide text-secondary uppercase">
            Share this poster
          </h2>
          <RegionInfographicShare
            url={absoluteUrl}
            title={title}
            text={shareText}
          />
          <p className="text-sm text-muted">
            Browse deals in{" "}
            <Link
              href={dealsHref}
              className="font-medium text-accent-soft underline-offset-2 hover:underline"
            >
              {suburb.name}
            </Link>
            .
          </p>
        </section>

        {nearbySuburbs.length > 0 && (
          <section className="space-y-4">
            <h2 className="text-xl font-semibold text-foreground">
              Nearby suburbs
            </h2>
            <ul className="grid gap-2 sm:grid-cols-2">
              {nearbySuburbs.map((nearby) => (
                <NearbySuburbCard key={nearby.id} suburb={nearby} />
              ))}
            </ul>
          </section>
        )}
      </div>
    );
  }

  const region = await findRegionBySlug(slug);
  if (!region) {
    notFound();
  }

  const { facts, suburbs } = await loadRegionInfographicFacts({
    regionId: region.id,
    regionName: region.name,
  });

  const composition = composeRegionInfographic(facts, "page");
  const path = regionStatisticsPath(region.name);
  const absoluteUrl = `${siteUrl()}${path}`;
  const title = formatRegionInfographicTitle(region.name);
  const shareText = formatRegionInfographicDescription(facts);

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-10 px-4 py-10 md:px-6">
      <RegionFocusNotice regionName={region.name} />

      <RegionInfographicPoster composition={composition} />

      <section className="space-y-3">
        <h2 className="text-sm font-medium tracking-wide text-secondary uppercase">
          Share this poster
        </h2>
        <RegionInfographicShare
          url={absoluteUrl}
          title={title}
          text={shareText}
        />
        <p className="text-sm text-muted">
          Browse deals in{" "}
          <Link
            href={regionPath(region.name)}
            className="font-medium text-accent-soft underline-offset-2 hover:underline"
          >
            {region.name}
          </Link>
          .
        </p>
      </section>

      <section className="space-y-4">
        <div className="space-y-1">
          <h2 className="text-xl font-semibold text-foreground">
            Dive into individual suburbs
          </h2>
        </div>
        <RegionStatisticsView suburbs={suburbs} regionName={region.name} />
      </section>
    </div>
  );
}
