import { Suspense } from "react";
import Image from "next/image";
import type { Metadata } from "next";
import { DuskAtmosphere } from "@/components/DuskAtmosphere";
import { PopularRegions } from "@/components/PopularRegions";
import { SearchUrlRedirect } from "@/components/SearchUrlRedirect";
import { listRegions } from "@/lib/search/queries";

export const dynamic = "force-dynamic";

const socialTitle = "DuskRoute: Your evening starts here";

const description =
  "Find happy hour deals as the day fades into night — after-work drinks or an all-night plan. Pick a region or jump to deals near you.";

export const metadata: Metadata = {
  title: socialTitle,
  description,
  alternates: {
    canonical: "/",
  },
  openGraph: {
    title: socialTitle,
    description,
    type: "website",
    url: "/",
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

      <div className="relative flex flex-1 flex-col">
        <section className="relative flex min-h-[55vh] flex-col overflow-hidden md:min-h-[60vh]">
          <Image
            src="/landing-hero.jpg"
            alt=""
            fill
            priority
            sizes="100vw"
            className="object-cover object-center"
          />

          {/* Readability scrim — heavier left (bright sunset) and bottom fade into page */}
          <div
            className="absolute inset-0"
            style={{
              background: `
                linear-gradient(
                  90deg,
                  rgb(8 20 38 / 0.72) 0%,
                  rgb(8 20 38 / 0.45) 45%,
                  rgb(8 20 38 / 0.55) 100%
                ),
                linear-gradient(
                  180deg,
                  rgb(8 20 38 / 0.35) 0%,
                  rgb(8 20 38 / 0.25) 40%,
                  rgb(8 20 38 / 0.85) 78%,
                  var(--background) 100%
                )
              `,
            }}
            aria-hidden
          />

          <header className="animate-dusk-rise relative z-10 mx-auto flex w-full max-w-5xl flex-1 flex-col items-center justify-center gap-6 px-4 py-20 text-center md:px-6 md:py-28">
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
        </section>

        <section className="relative overflow-hidden">
          <DuskAtmosphere />

          <div
            className="animate-dusk-rise relative mx-auto w-full max-w-5xl px-4 pb-16 pt-4 md:px-6 md:pb-20 md:pt-6"
            style={{ animationDelay: "0.15s" }}
          >
            <PopularRegions
              regions={regions}
              title="Where to?"
              description="Jump to deals near you, or pick a region to explore."
            />
          </div>
        </section>
      </div>
    </>
  );
}
