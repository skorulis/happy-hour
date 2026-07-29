import { BeerGlassWeekdayChart } from "@/components/infographic/BeerGlassWeekdayChart";
import { CoverageRingsChart } from "@/components/infographic/CoverageRingsChart";
import { DayHourHeatChart } from "@/components/infographic/DayHourHeatChart";
import { DensityBarsChart } from "@/components/infographic/DensityBarsChart";
import {
  DrinkBarsChart,
  ProductBarsChart,
} from "@/components/infographic/DrinkBarsChart";
import type { InfographicComposition } from "@/lib/infographic/types";
import {
  formatRegionInfographicTitle,
  slotEyebrow,
  slotHeadline,
  slotSupporting,
} from "@/lib/infographic/copy";
import Image from "next/image";

type RegionInfographicPosterProps = {
  composition: InfographicComposition;
};

export function RegionInfographicPoster({
  composition,
}: RegionInfographicPosterProps) {
  const coverageTriad = composition.slots.find(
    (slot) => slot.id === "coverageTriad",
  );
  const weekdayMix = composition.slots.find((slot) => slot.id === "weekdayMix");
  const dayHourHeat = composition.slots.find(
    (slot) => slot.id === "dayHourHeat",
  );
  const topProducts = composition.slots.find(
    (slot) => slot.id === "topProducts",
  );
  const topFood = composition.slots.find((slot) => slot.id === "topFood");
  const topDensity = composition.slots.find((slot) => slot.id === "topDensity");

  return (
    <div id="region-infographic-poster">
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
        <header>
          <h1 className="text-2xl font-semibold tracking-tight text-foreground sm:text-3xl md:text-4xl">
            {formatRegionInfographicTitle(composition.regionName)}
          </h1>
        </header>

        {coverageTriad && coverageTriad.id === "coverageTriad" ? (
          <div>
            <CoverageRingsChart rings={coverageTriad.rings} />
          </div>
        ) : null}

        {weekdayMix || dayHourHeat ? (
          <div className="flex flex-col gap-8 md:flex-row md:items-start md:gap-8">
            {weekdayMix && weekdayMix.id === "weekdayMix" ? (
              <div className="min-w-0 space-y-4 md:w-[42%] md:shrink-0">
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
              <div className="min-w-0 flex-1 space-y-4 md:mt-14">
                <DayHourHeatChart
                  cells={dayHourHeat.cells}
                  listBasePath={composition.listBasePath}
                  className="w-full max-w-xl md:max-w-none"
                />
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
              </div>
            ) : null}
          </div>
        ) : null}

        {topProducts || topFood ? (
          <div className="flex flex-col gap-8 md:flex-row md:items-start md:gap-8">
            {topProducts && topProducts.id === "topProducts" ? (
              <div
                className={`min-w-0 space-y-3 ${
                  topFood ? "md:flex-1" : "w-full"
                }`}
              >
                <div className="space-y-1">
                  <p className="text-xs font-medium tracking-[0.18em] text-accent-soft uppercase">
                    {slotEyebrow(topProducts)}
                  </p>
                  <p
                    className={`font-medium text-secondary ${
                      topFood ? "text-base" : "text-lg"
                    }`}
                  >
                    {slotHeadline(topProducts)}
                    {slotSupporting(topProducts)
                      ? ` · ${slotSupporting(topProducts)}`
                      : null}
                  </p>
                </div>
                <DrinkBarsChart
                  products={topProducts.products}
                  dense={Boolean(topFood)}
                />
              </div>
            ) : null}
            {topFood && topFood.id === "topFood" ? (
              <div
                className={`min-w-0 space-y-3 ${
                  topProducts ? "md:flex-1" : "w-full"
                }`}
              >
                <div className="space-y-1">
                  <p className="text-xs font-medium tracking-[0.18em] text-accent-soft uppercase">
                    {slotEyebrow(topFood)}
                  </p>
                  <p
                    className={`font-medium text-secondary ${
                      topProducts ? "text-base" : "text-lg"
                    }`}
                  >
                    {slotHeadline(topFood)}
                    {slotSupporting(topFood)
                      ? ` · ${slotSupporting(topFood)}`
                      : null}
                  </p>
                </div>
                <ProductBarsChart
                  products={topFood.products}
                  ariaLabel="Top food mentions"
                  fallbackIcon="UtensilsCrossed"
                  dense={Boolean(topProducts)}
                />
              </div>
            ) : null}
          </div>
        ) : null}

        {topDensity && topDensity.id === "topDensity" ? (
          <div className="space-y-4">
            <div className="space-y-1">
              <p className="text-xs font-medium tracking-[0.18em] text-accent-soft uppercase">
                {slotEyebrow(topDensity)}
              </p>
              <p className="text-lg font-medium text-secondary">
                {slotHeadline(topDensity)}
                {slotSupporting(topDensity)
                  ? ` · ${slotSupporting(topDensity)}`
                  : null}
              </p>
            </div>
            <DensityBarsChart
              suburbs={topDensity.suburbs}
              metric={topDensity.metric}
            />
          </div>
        ) : null}

        <div className="hidden items-center gap-2.5" data-capture-only>
          <Image
            src="/icon.png"
            alt=""
            width={28}
            height={28}
            className="h-7 w-7 rounded-full"
            aria-hidden
          />
          <div className="flex flex-col gap-0.5">
            <span className="text-xs font-semibold tracking-[0.12em] text-accent-soft">
              DuskRoute.com
            </span>
            <span className="text-[10px] font-medium tracking-[0.15em] text-muted uppercase">
              your night starts here
            </span>
          </div>
        </div>
      </div>
      </article>
    </div>
  );
}
