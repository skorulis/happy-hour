import Image from "next/image";
import { BeerGlassWeekdayChart } from "@/components/infographic/BeerGlassWeekdayChart";
import type { InfographicComposition, InfographicSlot } from "@/lib/infographic/types";
import {
  formatRegionInfographicTitle,
  slotEyebrow,
  slotHeadline,
  slotSupporting,
} from "@/lib/infographic/copy";

type RegionInfographicPosterProps = {
  composition: InfographicComposition;
};

function TextSlot({ slot }: { slot: InfographicSlot }) {
  return (
    <div className="space-y-1">
      <p className="text-xs font-medium tracking-[0.16em] text-muted uppercase">
        {slotEyebrow(slot)}
      </p>
      <p className="text-xl font-semibold tracking-tight text-foreground sm:text-2xl">
        {slotHeadline(slot)}
      </p>
      {slotSupporting(slot) ? (
        <p className="text-sm text-secondary">{slotSupporting(slot)}</p>
      ) : null}
    </div>
  );
}

export function RegionInfographicPoster({
  composition,
}: RegionInfographicPosterProps) {
  const headline = composition.slots.find((slot) => slot.id === "headline");
  const weekdayMix = composition.slots.find((slot) => slot.id === "weekdayMix");
  const rest = composition.slots.filter(
    (slot) => slot.id !== "headline" && slot.id !== "weekdayMix",
  );

  return (
    <article
      className="relative overflow-hidden rounded-2xl border border-border bg-surface-elevated shadow-card"
      aria-label={`Infographic for ${composition.regionName}`}
    >
      <div
        className="pointer-events-none absolute inset-0 opacity-90"
        style={{
          background:
            "radial-gradient(ellipse 100% 80% at 20% -20%, rgb(124 58 87 / 0.5) 0%, transparent 55%), radial-gradient(ellipse 70% 50% at 100% 0%, rgb(245 158 11 / 0.18) 0%, transparent 50%), linear-gradient(165deg, #0c1a2e 0%, #081426 48%, #06101f 100%)",
        }}
        aria-hidden
      />

      <div className="relative flex flex-col gap-8 p-6 sm:p-8 md:p-10">
        <header className="flex flex-col items-start gap-4 sm:flex-row sm:items-center sm:gap-5">
          <Image
            src="/icon.png"
            alt=""
            width={64}
            height={64}
            className="h-14 w-14 rounded-full sm:h-16 sm:w-16"
            priority
          />
          <div className="min-w-0 space-y-1">
            <p className="text-xs font-medium tracking-[0.2em] text-accent-soft uppercase">
              DuskRoute
            </p>
            <h2 className="text-2xl font-semibold tracking-tight text-foreground sm:text-3xl md:text-4xl">
              {composition.regionName}
            </h2>
            <p className="text-sm text-secondary sm:text-base">
              {formatRegionInfographicTitle(composition.regionName)}
            </p>
          </div>
        </header>

        {headline ? (
          <div className="space-y-1 border-b border-border-subtle pb-6">
            <p className="text-xs font-medium tracking-[0.18em] text-accent-soft uppercase">
              {slotEyebrow(headline)}
            </p>
            <p className="text-4xl font-semibold tracking-tight text-foreground sm:text-5xl">
              {slotHeadline(headline)}
            </p>
            {slotSupporting(headline) ? (
              <p className="text-base text-secondary sm:text-lg">
                {slotSupporting(headline)}
              </p>
            ) : null}
          </div>
        ) : null}

        {weekdayMix && weekdayMix.id === "weekdayMix" ? (
          <div className="space-y-4 border-b border-border-subtle pb-8">
            <div className="space-y-1">
              <p className="text-xs font-medium tracking-[0.18em] text-accent-soft uppercase">
                {slotEyebrow(weekdayMix)}
              </p>
              <p className="text-lg font-medium text-secondary">
                {slotHeadline(weekdayMix)}
                {slotSupporting(weekdayMix)
                  ? ` · ${slotSupporting(weekdayMix)}`
                  : null}
              </p>
            </div>
            <BeerGlassWeekdayChart
              days={weekdayMix.days}
              peakDayOfWeek={weekdayMix.peakDayOfWeek}
            />
          </div>
        ) : null}

        {rest.length > 0 ? (
          <div className="grid gap-5 sm:grid-cols-2">
            {rest.map((slot) => (
              <div
                key={slot.id}
                className={slot.id === "topProducts" ? "sm:col-span-2" : undefined}
              >
                <TextSlot slot={slot} />
              </div>
            ))}
          </div>
        ) : null}
      </div>
    </article>
  );
}
