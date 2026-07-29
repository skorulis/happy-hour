import { notFound } from "next/navigation";
import { composeRegionInfographic } from "@/lib/infographic/compose";
import {
  loadRegionInfographicFacts,
  loadSuburbInfographicFacts,
} from "@/lib/infographic/load-facts";
import { renderRegionInfographicImage } from "@/lib/infographic/render-image";
import { INFOGRAPHIC_IMAGE_SIZES } from "@/lib/infographic/types";
import {
  findRegionBySlug,
  findSuburbByWhereSlug,
} from "@/lib/search/queries";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";
export const alt = "Happy hour statistics";
export const size = INFOGRAPHIC_IMAGE_SIZES.og;
export const contentType = "image/png";

type OpenGraphImageProps = {
  params: Promise<{ suburb: string }>;
};

export default async function OpenGraphImage({ params }: OpenGraphImageProps) {
  const { suburb: slug } = await params;

  const suburb = await findSuburbByWhereSlug(slug);
  if (suburb) {
    const { facts } = await loadSuburbInfographicFacts({
      suburbId: suburb.id,
      suburbName: suburb.name,
      suburbPostcode: suburb.postcode,
    });
    const composition = composeRegionInfographic(facts, "og");
    return renderRegionInfographicImage(composition, "og");
  }

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
