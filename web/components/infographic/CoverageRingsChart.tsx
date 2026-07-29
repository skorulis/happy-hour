import {
  COVERAGE_RING_CENTER,
  COVERAGE_RING_FILL,
  COVERAGE_RING_RADIUS,
  COVERAGE_RING_STROKE,
  COVERAGE_RING_TRACK,
  COVERAGE_RING_VIEWBOX,
  clampCoveragePercent,
  coverageRingDash,
  coverageRingEyebrow,
  coverageRingScaleUnitLabel,
  coverageTriadAriaLabel,
} from "@/lib/infographic/coverage-rings";
import { formatCoveragePercent, formatDealCount } from "@/lib/infographic/copy";
import type { CoverageTriadRing } from "@/lib/infographic/types";

type CoverageRingsChartProps = {
  rings: CoverageTriadRing[];
  className?: string;
};

function CoverageRing({
  ring,
  className,
}: {
  ring: CoverageTriadRing;
  className?: string;
}) {
  const dash = coverageRingDash(ring.percent);
  const percentLabel = formatCoveragePercent(
    clampCoveragePercent(ring.percent),
  );
  const unit = coverageRingScaleUnitLabel(ring.scaleUnit, ring.scaleCount);

  return (
    <div
      className={`flex flex-col items-center gap-3 text-center ${className ?? ""}`}
    >
      <p className="text-xs font-medium tracking-[0.16em] text-accent-soft uppercase">
        {coverageRingEyebrow(ring)}
      </p>
      <div className="relative h-32 w-32 sm:h-40 sm:w-40">
        <svg
          viewBox={`0 0 ${COVERAGE_RING_VIEWBOX} ${COVERAGE_RING_VIEWBOX}`}
          className="h-full w-full"
          aria-hidden
        >
          <circle
            cx={COVERAGE_RING_CENTER}
            cy={COVERAGE_RING_CENTER}
            r={COVERAGE_RING_RADIUS}
            fill="none"
            stroke={COVERAGE_RING_TRACK}
            strokeWidth={COVERAGE_RING_STROKE}
          />
          <g
            transform={`rotate(-90 ${COVERAGE_RING_CENTER} ${COVERAGE_RING_CENTER})`}
          >
            <circle
              cx={COVERAGE_RING_CENTER}
              cy={COVERAGE_RING_CENTER}
              r={COVERAGE_RING_RADIUS}
              fill="none"
              stroke={COVERAGE_RING_FILL}
              strokeWidth={COVERAGE_RING_STROKE}
              strokeLinecap="round"
              strokeDasharray={dash.dasharray}
              strokeDashoffset={dash.dashoffset}
            />
          </g>
        </svg>
        <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center px-3">
          <p className="text-2xl font-semibold tracking-tight text-foreground tabular-nums sm:text-3xl">
            {formatDealCount(ring.scaleCount)}
          </p>
          <p className="text-xs font-medium tracking-wide text-secondary uppercase">
            {unit}
          </p>
          <p className="mt-1 text-sm font-medium text-accent-soft tabular-nums">
            {percentLabel}
          </p>
        </div>
      </div>
    </div>
  );
}

export function CoverageRingsChart({
  rings,
  className,
}: CoverageRingsChartProps) {
  if (rings.length === 0) return null;

  const layoutClass =
    className ??
    (rings.length === 1
      ? "flex justify-center"
      : "grid grid-cols-2 gap-6 sm:grid-cols-3 sm:gap-4 md:gap-6");

  return (
    <div
      className={layoutClass}
      role="img"
      aria-label={coverageTriadAriaLabel(rings)}
    >
      {rings.map((ring, index) => (
        <CoverageRing
          key={ring.id}
          ring={ring}
          className={
            rings.length > 1 && index === 2
              ? "col-span-2 justify-self-center sm:col-span-1 sm:justify-self-auto"
              : undefined
          }
        />
      ))}
    </div>
  );
}
