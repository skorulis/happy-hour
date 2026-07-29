import Image from "next/image";
import { BeerGlassWeekdayChart } from "@/components/infographic/BeerGlassWeekdayChart";
import { DayHourHeatChart } from "@/components/infographic/DayHourHeatChart";
import { DrinkBarsChart } from "@/components/infographic/DrinkBarsChart";
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
  const eyebrow = slotEyebrow(slot);
  const supporting = slotSupporting(slot);
  return (
    <div className="space-y-1">
      {eyebrow ? (
        <p className="text-xs font-medium tracking-[0.16em] text-muted uppercase">
          {eyebrow}
        </p>
      ) : null}
      <p className="text-xl font-semibold tracking-tight text-foreground sm:text-2xl">
        {slotHeadline(slot)}
      </p>
      {supporting ? (
        <p className="text-sm text-secondary">{supporting}</p>
      ) : null}
    </div>
  );
}

export function RegionInfographicPoster({
  composition,
}: RegionInfographicPosterProps) {
  const headline = composition.slots.find((slot) => slot.id === "headline");
  const weekdayMix = composition.slots.find((slot) => slot.id === "weekdayMix");
  const dayHourHeat = composition.slots.find(
    (slot) => slot.id === "dayHourHeat",
  );
  const topProducts = composition.slots.find(
    (slot) => slot.id === "topProducts",
  );
  const rest = composition.slots.filter(
    (slot) =>
      slot.id !== "headline" &&
      slot.id !== "weekdayMix" &&
      slot.id !== "dayHourHeat" &&
      slot.id !== "topProducts",
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
              {formatRegionInfographicTitle(composition.regionName)}
            </h2>
          </div>
        </header>

        {headline ? (
          <div className="space-y-1 border-b border-border-subtle pb-6">
            <p className="text-xs font-medium tracking-[0.18em] text-accent-soft uppercase">
              {slotHeadline(headline)}
            </p>
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

        {dayHourHeat && dayHourHeat.id === "dayHourHeat" ? (
          <div className="space-y-4 border-b border-border-subtle pb-8">
            <div className="space-y-1">
              <p className="text-xs font-medium tracking-[0.18em] text-accent-soft uppercase">
                {slotEyebrow(dayHourHeat)}
              </p>
              <p className="text-lg font-medium text-secondary">
                {slotHeadline(dayHourHeat)}
                {slotSupporting(dayHourHeat)
                  ? ` · ${slotSupporting(dayHourHeat)}`
                  : null}
              </p>
            </div>
            <DayHourHeatChart
              cells={dayHourHeat.cells}
              regionName={composition.regionName}
            />
          </div>
        ) : null}

        {topProducts && topProducts.id === "topProducts" ? (
          <div className="space-y-4 border-b border-border-subtle pb-8">
            <div className="space-y-1">
              <p className="text-xs font-medium tracking-[0.18em] text-accent-soft uppercase">
                {slotEyebrow(topProducts)}
              </p>
              <p className="text-lg font-medium text-secondary">
                {slotHeadline(topProducts)}
                {slotSupporting(topProducts)
                  ? ` · ${slotSupporting(topProducts)}`
                  : null}
              </p>
            </div>
            <DrinkBarsChart products={topProducts.products} />
          </div>
        ) : null}

        {rest.length > 0 ? (
          <div className="grid gap-5 sm:grid-cols-2">
            {rest.map((slot) => (
              <div key={slot.id}>
                <TextSlot slot={slot} />
              </div>
            ))}
          </div>
        ) : null}
      </div>
    </article>
  );
}
