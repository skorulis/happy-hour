import { notFound } from "next/navigation";
import { composeRegionInfographic } from "@/lib/infographic/compose";
import {
  loadRegionInfographicFacts,
  loadSuburbInfographicFacts,
} from "@/lib/infographic/load-facts";
import { renderRegionInfographicImage } from "@/lib/infographic/render-image";
import type { InfographicFormat } from "@/lib/infographic/types";
import {
  findRegionBySlug,
  findSuburbByWhereSlug,
} from "@/lib/search/queries";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

type CardRouteProps = {
  params: Promise<{ suburb: string }>;
};

function parseFormat(
  value: string | null,
): Exclude<InfographicFormat, "page" | "og"> {
  if (value === "story") return "story";
  return "square";
}

export async function GET(request: Request, { params }: CardRouteProps) {
  const { suburb: slug } = await params;

  const format = parseFormat(new URL(request.url).searchParams.get("format"));

  const suburb = await findSuburbByWhereSlug(slug);
  if (suburb) {
    const { facts } = await loadSuburbInfographicFacts({
      suburbId: suburb.id,
      suburbName: suburb.name,
      suburbPostcode: suburb.postcode,
    });
    const composition = composeRegionInfographic(facts, format);
    return renderRegionInfographicImage(composition, format);
  }

  const region = await findRegionBySlug(slug);
  if (!region) {
    notFound();
  }

  const { facts } = await loadRegionInfographicFacts({
    regionId: region.id,
    regionName: region.name,
  });
  const composition = composeRegionInfographic(facts, format);
  return renderRegionInfographicImage(composition, format);
}
