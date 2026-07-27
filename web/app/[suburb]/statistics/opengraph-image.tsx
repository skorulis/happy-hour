import { notFound } from "next/navigation";
import { composeRegionInfographic } from "@/lib/infographic/compose";
import { loadRegionInfographicFacts } from "@/lib/infographic/load-facts";
import { renderRegionInfographicImage } from "@/lib/infographic/render-image";
import { INFOGRAPHIC_IMAGE_SIZES } from "@/lib/infographic/types";
import { findRegionBySlug } from "@/lib/search/queries";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";
export const alt = "Region happy hour statistics";
export const size = INFOGRAPHIC_IMAGE_SIZES.og;
export const contentType = "image/png";

type OpenGraphImageProps = {
  params: Promise<{ suburb: string }>;
};

export default async function OpenGraphImage({ params }: OpenGraphImageProps) {
  const { suburb: slug } = await params;
  const region = await findRegionBySlug(slug);
  if (!region) {
    notFound();
  }

  const { facts } = await loadRegionInfographicFacts({
    regionId: region.id,
    regionName: region.name,
  });
  const composition = composeRegionInfographic(facts, "og");
  return renderRegionInfographicImage(composition, "og");
}
