import { Suspense } from "react";
import type { Metadata } from "next";
import { SearchPage } from "@/components/SearchPage";
import { SearchUrlRedirect } from "@/components/SearchUrlRedirect";
import { listPopularSuburbs } from "@/lib/search/queries";
import { parseDaysParam, parseWhatTokens } from "@/lib/search/url";

// Needs Postgres at request time — skip static prerender during Docker builds.
export const dynamic = "force-dynamic";

const socialTitle = "DuskRoute: Your evening starts here";

export const metadata: Metadata = {
  openGraph: {
    title: socialTitle,
  },
  twitter: {
    title: socialTitle,
  },
};

type HomePageProps = {
  searchParams: Promise<{ days?: string; q?: string }>;
};

export default async function Home({ searchParams }: HomePageProps) {
  const { days: daysParam, q: whatParam } = await searchParams;
  const days = parseDaysParam(daysParam ?? null);
  const what = whatParam ? parseWhatTokens(whatParam) : [];
  // Empty days → omit day filter so SSR HTML includes the full week for crawlers.
  // Explicit ?days= stays honest for deep links.
  const popularSuburbs = await listPopularSuburbs(20, {
    ...(days.length > 0 ? { days } : {}),
    ...(what.length > 0 ? { query: what.join(",") } : {}),
  });

  return (
    <>
      {/* Isolate useSearchParams — do not wrap SearchPage or SSR suburbs vanish. */}
      <Suspense fallback={null}>
        <SearchUrlRedirect />
      </Suspense>
      <SearchPage
        popularSuburbs={popularSuburbs}
        initialDays={days}
        initialWhat={what}
      />
    </>
  );
}
