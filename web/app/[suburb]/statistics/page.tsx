import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { RegionStatisticsView } from "@/components/RegionStatisticsView";
import { findRegionBySlug, listSuburbStatistics } from "@/lib/search/queries";
import { regionStatisticsPath } from "@/lib/search/slugs";

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

  const title = `Statistics for ${region.name}`;
  const description = `Compare venues and deals by density and population across suburbs in ${region.name}.`;

  return {
    title,
    description,
    alternates: {
      canonical: regionStatisticsPath(region.name),
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

  const suburbs = await listSuburbStatistics({ regionId: region.id });

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-4 py-10 md:px-6">
      <header>
        <h1 className="text-3xl font-bold text-foreground">
          Statistics for {region.name}
        </h1>
      </header>

      <section>
        <RegionStatisticsView suburbs={suburbs} regionName={region.name} />
      </section>
    </div>
  );
}
