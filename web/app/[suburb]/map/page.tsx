import { Suspense } from "react";
import { notFound } from "next/navigation";
import { MapPage } from "@/components/MapPage";
import { findSuburbByWhereSlug } from "@/lib/search/queries";
import { NEARBY_WHERE_SLUG } from "@/lib/search/slugs";

type SuburbMapPageProps = {
  params: Promise<{ suburb: string }>;
};

export default async function SuburbMapPage({ params }: SuburbMapPageProps) {
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
        <div className="relative flex min-h-0 flex-1 flex-col">
          <div className="absolute inset-0 flex items-center justify-center bg-background text-sm text-muted">
            Loading map...
          </div>
        </div>
      }
    >
      <MapPage initialWhere={initialWhere} />
    </Suspense>
  );
}
