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
import { loadRegionInfographicFacts } from "@/lib/infographic/load-facts";
import { findRegionBySlug } from "@/lib/search/queries";
import { regionPath, regionStatisticsPath } from "@/lib/search/slugs";
import { siteUrl } from "@/lib/site-url";

export const dynamic = "force-dynamic";

type RegionStatisticsPageProps = {
  params: Promise<{ suburb: string }>;
};

export async function generateMetadata({
  params,
}: RegionStatisticsPageProps): Promise<Metadata> {
  const { suburb: slug } = await params;
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

export default async function RegionStatisticsPage({
  params,
}: RegionStatisticsPageProps) {
  const { suburb: slug } = await params;
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
          downloadPath={`${path}/card?format=square`}
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
            Explore the rankings
          </h2>
          <p className="text-sm text-muted">
            Compare suburbs by density and population.
          </p>
        </div>
        <RegionStatisticsView suburbs={suburbs} regionName={region.name} />
      </section>
    </div>
  );
}
