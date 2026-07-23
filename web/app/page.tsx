import { Suspense } from "react";
import Image from "next/image";
import type { Metadata } from "next";
import { DuskAtmosphere } from "@/components/DuskAtmosphere";
import { PopularRegions } from "@/components/PopularRegions";
import { SearchUrlRedirect } from "@/components/SearchUrlRedirect";
import { listRegions } from "@/lib/search/queries";

export const dynamic = "force-dynamic";

const socialTitle = "DuskRoute: Your evening starts here";

export const metadata: Metadata = {
  title: socialTitle,
  description:
    "Find happy hour deals as the day fades into night — after-work drinks or an all-night plan. Pick a region or jump to deals near you.",
  openGraph: {
    title: socialTitle,
  },
  twitter: {
    title: socialTitle,
  },
};

export default async function Home() {
  const regions = await listRegions();

  return (
    <>
      {/* Isolate useSearchParams — do not wrap page content or SSR regions vanish. */}
      <Suspense fallback={null}>
        <SearchUrlRedirect />
      </Suspense>

      <div className="relative flex flex-1 flex-col overflow-hidden">
        <DuskAtmosphere />

        <div className="relative mx-auto flex w-full max-w-5xl flex-1 flex-col gap-12 px-4 py-16 md:gap-16 md:px-6 md:py-20">
          <header className="animate-dusk-rise flex flex-col items-center gap-6 text-center">
            <Image
              src="/icon.png"
              alt=""
              width={112}
              height={112}
              className="animate-dusk-glow-pulse h-24 w-24 rounded-full md:h-28 md:w-28"
              priority
            />

            <p className="text-sm font-medium tracking-[0.2em] text-accent-soft uppercase">
              DuskRoute
            </p>

            <div className="flex max-w-lg flex-col gap-4">
              <h1 className="text-3xl font-semibold tracking-tight text-foreground md:text-4xl">
                Your evening starts here
              </h1>
              <p className="text-base leading-relaxed text-muted md:text-lg">
                DuskRoute is how your evening begins. Whether you&apos;re ducking
                out for a few drinks after work or chasing an all-night bender,
                this is your map to the happy hours that set the night in motion.
              </p>
            </div>
          </header>

          <section
            className="animate-dusk-rise"
            style={{ animationDelay: "0.15s" }}
          >
            <PopularRegions
              regions={regions}
              title="Where to?"
              description="Jump to deals near you, or pick a region to explore."
            />
          </section>
        </div>
      </div>
    </>
  );
}
