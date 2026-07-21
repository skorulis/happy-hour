import { Suspense } from "react";
import { SearchPage } from "@/components/SearchPage";
import { SearchUrlRedirect } from "@/components/SearchUrlRedirect";
import { listPopularSuburbs } from "@/lib/search/queries";

// Needs Postgres at request time — skip static prerender during Docker builds.
export const dynamic = "force-dynamic";

export default async function Home() {
  const popularSuburbs = await listPopularSuburbs(20);

  return (
    <>
      <Suspense fallback={null}>
        <SearchUrlRedirect />
      </Suspense>
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
        <SearchPage popularSuburbs={popularSuburbs} />
      </Suspense>
    </>
  );
}
