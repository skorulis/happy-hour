import { Suspense } from "react";
import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { SearchPage } from "@/components/SearchPage";
import { findSuburbByWhereSlug } from "@/lib/search/queries";
import { formatSuburbDealsMetadataTitle } from "@/lib/search/schedule";
import { NEARBY_WHERE_SLUG, suburbWherePath } from "@/lib/search/slugs";
import { parseDaysParam, parseWhatTokens } from "@/lib/search/url";

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
  if (!suburb) {
    return {};
  }

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

export default async function SuburbSearchPage({
  params,
}: SuburbSearchPageProps) {
  const { suburb: whereSlug } = await params;

  if (whereSlug === NEARBY_WHERE_SLUG) {
    notFound();
  }

  const suburb = await findSuburbByWhereSlug(whereSlug);
  if (!suburb) {
    notFound();
  }

  const initialWhere = {
    kind: "suburb" as const,
    id: suburb.id,
    suburb,
  };

  return (
    <Suspense
      fallback={
        <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-6 py-10">
          <header>
            <h1 className="text-3xl font-bold text-foreground">
            Your evening starts here
            </h1>
          </header>
        </div>
      }
    >
      <SearchPage initialWhere={initialWhere} />
    </Suspense>
  );
}
