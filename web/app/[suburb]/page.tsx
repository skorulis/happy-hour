import { Suspense } from "react";
import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { SearchPage } from "@/components/SearchPage";
import { findSuburbByWhereSlug } from "@/lib/search/queries";
import { NEARBY_WHERE_SLUG, suburbWherePath } from "@/lib/search/slugs";

type SuburbSearchPageProps = {
  params: Promise<{ suburb: string }>;
};

export async function generateMetadata({
  params,
}: SuburbSearchPageProps): Promise<Metadata> {
  const { suburb: whereSlug } = await params;
  if (whereSlug === NEARBY_WHERE_SLUG) {
    return {};
  }

  const suburb = await findSuburbByWhereSlug(whereSlug);
  if (!suburb) {
    return {};
  }

  return {
    title: `Happy hour deals in ${suburb.name}`,
    description: `Find pub and bar happy hour deals in ${suburb.name}${suburb.postcode ? ` (${suburb.postcode})` : ""}.`,
    alternates: {
      canonical: suburbWherePath(suburb.name, suburb.postcode),
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
              Find pub and bar deals
            </h1>
          </header>
        </div>
      }
    >
      <SearchPage initialWhere={initialWhere} />
    </Suspense>
  );
}
