import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { PopularSuburbs } from "@/components/PopularSuburbs";
import { RegionFocusNotice } from "@/components/RegionFocusNotice";
import { findRegionBySlug, listAllSuburbs } from "@/lib/search/queries";
import { regionAllSuburbsPath } from "@/lib/search/slugs";

export const dynamic = "force-dynamic";

type RegionAllSuburbsPageProps = {
  params: Promise<{ suburb: string }>;
};

export async function generateMetadata({
  params,
}: RegionAllSuburbsPageProps): Promise<Metadata> {
  const { suburb: slug } = await params;
  const region = await findRegionBySlug(slug);
  if (!region) {
    return {};
  }

  const title = `All suburbs in ${region.name}`;
  const description = `Browse every suburb in ${region.name}, ordered by deal count.`;

  return {
    title,
    description,
    alternates: {
      canonical: regionAllSuburbsPath(region.name),
    },
  };
}

export default async function RegionAllSuburbsPage({
  params,
}: RegionAllSuburbsPageProps) {
  const { suburb: slug } = await params;
  const region = await findRegionBySlug(slug);
  if (!region) {
    notFound();
  }

  const suburbs = await listAllSuburbs({ regionId: region.id });

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-4 py-10 md:px-6">
      <header className="flex flex-col gap-4">
        <h1 className="text-3xl font-bold text-foreground">
          All suburbs in {region.name}
        </h1>
        <RegionFocusNotice regionName={region.name} />
      </header>

      <section>
        <PopularSuburbs
          suburbs={suburbs}
          title={`All suburbs in ${region.name}`}
          description="Browse every suburb in this region."
        />
      </section>
    </div>
  );
}
