import { ImageResponse } from "next/og";
import {
  BEER_GLASS_CHART_VIEWBOX,
  buildBeerGlassGeometry,
} from "@/lib/infographic/beer-glass";
import type {
  InfographicComposition,
  InfographicFormat,
  InfographicSlot,
} from "@/lib/infographic/types";
import { INFOGRAPHIC_IMAGE_SIZES } from "@/lib/infographic/types";
import {
  formatRegionInfographicTitle,
  slotEyebrow,
  slotHeadline,
  slotSupporting,
} from "@/lib/infographic/copy";

const COLORS = {
  bg: "#081426",
  fg: "#f8fafc",
  secondary: "#cbd5e1",
  muted: "#94a3b8",
  accentSoft: "#fdba74",
  border: "#3b414d",
};

function SlotBlock({
  eyebrow,
  headline,
  supporting,
  compact,
}: {
  eyebrow: string;
  headline: string;
  supporting: string | null;
  compact?: boolean;
}) {
  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        gap: compact ? 4 : 6,
        flexShrink: 1,
        minWidth: 0,
      }}
    >
      <div
        style={{
          display: "flex",
          fontSize: compact ? 18 : 22,
          fontWeight: 600,
          letterSpacing: "0.14em",
          textTransform: "uppercase",
          color: COLORS.accentSoft,
        }}
      >
        {eyebrow}
      </div>
      <div
        style={{
          display: "flex",
          fontSize: compact ? 36 : 48,
          fontWeight: 700,
          lineHeight: 1.1,
          color: COLORS.fg,
        }}
      >
        {headline}
      </div>
      {supporting ? (
        <div
          style={{
            display: "flex",
            fontSize: compact ? 22 : 28,
            color: COLORS.secondary,
          }}
        >
          {supporting}
        </div>
      ) : null}
    </div>
  );
}

function WeekdayMixBlock({
  slot,
  compact,
}: {
  slot: Extract<InfographicSlot, { id: "weekdayMix" }>;
  compact?: boolean;
}) {
  const geometry = buildBeerGlassGeometry(slot.days);
  const chartHeight = compact ? 200 : 300;
  const chartWidth = Math.round(
    (chartHeight * BEER_GLASS_CHART_VIEWBOX.width) /
      BEER_GLASS_CHART_VIEWBOX.height,
  );

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "row",
        alignItems: "center",
        gap: compact ? 28 : 40,
        width: "100%",
      }}
    >
      <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
        <div
          style={{
            display: "flex",
            fontSize: compact ? 18 : 22,
            fontWeight: 600,
            letterSpacing: "0.14em",
            textTransform: "uppercase",
            color: COLORS.accentSoft,
          }}
        >
          {slotEyebrow(slot)}
        </div>
        <div
          style={{
            display: "flex",
            fontSize: compact ? 28 : 34,
            fontWeight: 600,
            color: COLORS.secondary,
          }}
        >
          {slotHeadline(slot)}
          {slotSupporting(slot) ? ` · ${slotSupporting(slot)}` : ""}
        </div>
      </div>

      <svg
        width={chartWidth}
        height={chartHeight}
        viewBox={geometry.chartViewBox}
      >
        <defs>
          <clipPath id="beer-glass-clip">
            <path d={geometry.clipPath} />
          </clipPath>
        </defs>
        <g clipPath="url(#beer-glass-clip)">
          {geometry.segments.map((segment) => (
            <rect
              key={`seg-${segment.dayOfWeek}`}
              x={0}
              y={segment.yTop}
              width={geometry.glassWidth}
              height={segment.yBottom - segment.yTop}
              fill={segment.color}
            />
          ))}
        </g>
        <path
          d={geometry.outlinePath}
          fill="none"
          stroke={geometry.outlineColor}
          strokeWidth="2.25"
        />
        {geometry.legend.map((item) =>
          item.leaderPath ? (
            <path
              key={`leader-${item.dayOfWeek}`}
              d={item.leaderPath}
              fill="none"
              stroke={geometry.leaderColor}
              strokeWidth="1.25"
            />
          ) : null,
        )}
        {geometry.legend.map((item) => {
          const isPeak = item.dayOfWeek === slot.peakDayOfWeek;
          return (
            <g key={`legend-${item.dayOfWeek}`}>
              <rect
                x={item.swatchX}
                y={item.y - item.swatchSize / 2}
                width={item.swatchSize}
                height={item.swatchSize}
                fill={item.color}
              />
              <text
                x={item.labelX}
                y={item.y + 3}
                fill={isPeak ? COLORS.fg : COLORS.secondary}
                fontSize="11"
                fontWeight={isPeak ? 700 : 500}
              >
                {`${item.label}  ${item.percent}%`}
              </text>
            </g>
          );
        })}
      </svg>
    </div>
  );
}

export function renderRegionInfographicImage(
  composition: InfographicComposition,
  format: Exclude<InfographicFormat, "page">,
): ImageResponse {
  const size = INFOGRAPHIC_IMAGE_SIZES[format];
  const isOg = format === "og";
  const isStory = format === "story";
  const headline = composition.slots.find((slot) => slot.id === "headline");
  const weekdayMix = composition.slots.find((slot) => slot.id === "weekdayMix");
  const rest = composition.slots.filter(
    (slot) => slot.id !== "headline" && slot.id !== "weekdayMix",
  );
  const gridColumns = isOg ? 3 : 2;

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          padding: isStory ? 72 : isOg ? 48 : 64,
          backgroundColor: COLORS.bg,
          backgroundImage:
            "radial-gradient(ellipse 100% 80% at 15% -10%, rgba(124, 58, 87, 0.55) 0%, transparent 55%), radial-gradient(ellipse 70% 50% at 100% 0%, rgba(245, 158, 11, 0.2) 0%, transparent 50%)",
          color: COLORS.fg,
          fontFamily: "sans-serif",
        }}
      >
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            gap: isOg ? 12 : 20,
          }}
        >
          <div
            style={{
              display: "flex",
              fontSize: isOg ? 22 : 28,
              fontWeight: 600,
              letterSpacing: "0.22em",
              textTransform: "uppercase",
              color: COLORS.accentSoft,
            }}
          >
            DuskRoute
          </div>
          <div
            style={{
              display: "flex",
              fontSize: isOg ? 56 : isStory ? 84 : 72,
              fontWeight: 700,
              lineHeight: 1.05,
            }}
          >
            {composition.regionName}
          </div>
          <div
            style={{
              display: "flex",
              fontSize: isOg ? 26 : 32,
              color: COLORS.secondary,
            }}
          >
            {formatRegionInfographicTitle(composition.regionName)}
          </div>
        </div>

        {headline ? (
          <div
            style={{
              display: "flex",
              flexDirection: "column",
              gap: 8,
              borderBottom: `2px solid ${COLORS.border}`,
              paddingBottom: isOg ? 16 : 24,
              marginTop: isOg ? 16 : 28,
            }}
          >
            <SlotBlock
              eyebrow={slotEyebrow(headline)}
              headline={slotHeadline(headline)}
              supporting={slotSupporting(headline)}
              compact={isOg}
            />
          </div>
        ) : null}

        {weekdayMix && weekdayMix.id === "weekdayMix" ? (
          <div
            style={{
              display: "flex",
              marginTop: isOg ? 20 : 28,
              marginBottom: isOg ? 12 : 20,
            }}
          >
            <WeekdayMixBlock slot={weekdayMix} compact={isOg} />
          </div>
        ) : null}

        <div
          style={{
            display: "flex",
            flexWrap: "wrap",
            gap: isOg ? 24 : 36,
            marginTop: isOg ? 8 : 16,
            flexGrow: 1,
            alignContent: isStory ? "flex-start" : "center",
          }}
        >
          {rest.map((slot) => (
            <div
              key={slot.id}
              style={{
                display: "flex",
                width: `${100 / gridColumns - 2}%`,
                minWidth: isOg ? 200 : 260,
              }}
            >
              <SlotBlock
                eyebrow={slotEyebrow(slot)}
                headline={slotHeadline(slot)}
                supporting={slotSupporting(slot)}
                compact={isOg || format === "square"}
              />
            </div>
          ))}
        </div>
      </div>
    ),
    {
      ...size,
      headers: {
        "Cache-Control": "public, s-maxage=3600, stale-while-revalidate=86400",
      },
    },
  );
}
