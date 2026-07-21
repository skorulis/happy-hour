import Image from "next/image";
import Link from "next/link";
import type { Metadata } from "next";
import { DuskAtmosphere } from "@/components/DuskAtmosphere";

export const metadata: Metadata = {
  title: "About | DuskRoute",
  description:
    "DuskRoute is your route to start the night — find happy hours for after-work drinks or an all-night bender.",
};

export default function AboutPage() {
  return (
    <div className="relative flex flex-1 flex-col items-center justify-center overflow-hidden px-6 py-20 text-center">
      <DuskAtmosphere />

      <div className="animate-dusk-rise relative flex max-w-lg flex-col items-center gap-6">
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

        <div className="flex flex-col gap-4">
          <h1 className="text-3xl font-semibold tracking-tight text-foreground md:text-4xl">
            Your route to start the night
          </h1>
          <p className="text-base leading-relaxed text-muted md:text-lg">
            DuskRoute is how your evening begins. Whether you&apos;re ducking
            out for a few drinks after work or chasing an all-night bender, this
            is your map to the happy hours that set the night in motion.
          </p>
        </div>

        <Link
          href="/"
          className="mt-2 rounded-lg bg-accent px-5 py-2.5 text-sm font-medium text-accent-fg transition-colors hover:bg-accent-hover"
        >
          Find happy hours
        </Link>
      </div>
    </div>
  );
}
