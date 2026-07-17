import { Suspense } from "react";
import { SearchPage } from "@/components/SearchPage";
import { SearchUrlRedirect } from "@/components/SearchUrlRedirect";
import { listPopularSuburbs } from "@/lib/search/queries";

export default async function Home() {
  const popularSuburbs = await listPopularSuburbs(10);

  return (
    <>
      <Suspense fallback={null}>
        <SearchUrlRedirect />
      </Suspense>
      <Suspense
        fallback={
          <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-6 py-10">
            <header>
              <h1 className="text-3xl font-bold text-zinc-900 dark:text-zinc-50">
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
