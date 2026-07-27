import { ImageResponse } from "next/og";
import {
  buildBeerGlassGeometry,
  WEEKDAY_CHART_COLORS,
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
import { DAY_ABBREVIATIONS } from "@/lib/search/schedule";

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
  const glassHeight = compact ? 200 : 280;
  const glassWidth = Math.round(
    (glassHeight * 100) / 160,
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
        width={glassWidth}
        height={glassHeight}
        viewBox={geometry.viewBox}
      >
        {geometry.segments.map((segment) => (
          <path
            key={segment.dayOfWeek}
            d={segment.d}
            fill={segment.color}
          />
        ))}
        {geometry.foamPath ? (
          <path d={geometry.foamPath} fill={geometry.foamColor} />
        ) : null}
        <path
          d={geometry.outlinePath}
          fill="none"
          stroke={geometry.outlineColor}
          strokeWidth="2.5"
        />
      </svg>

      <div
        style={{
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          gap: compact ? 4 : 6,
          height: glassHeight,
        }}
      >
        {[...slot.days].reverse().map((day) => {
          const isPeak = day.dayOfWeek === slot.peakDayOfWeek;
          const color =
            WEEKDAY_CHART_COLORS[day.dayOfWeek] ?? COLORS.accentSoft;
          return (
            <div
              key={day.dayOfWeek}
              style={{
                display: "flex",
                flexDirection: "row",
                alignItems: "center",
                gap: 8,
                fontSize: compact ? 20 : 24,
                fontWeight: isPeak ? 700 : 500,
                color: isPeak ? COLORS.fg : COLORS.secondary,
              }}
            >
              <div
                style={{
                  display: "flex",
                  width: 12,
                  height: 12,
                  backgroundColor: color,
                }}
              />
              <div style={{ display: "flex", width: 48 }}>
                {DAY_ABBREVIATIONS[day.dayOfWeek] ?? `D${day.dayOfWeek}`}
              </div>
              <div
                style={{
                  display: "flex",
                  color: isPeak ? COLORS.accentSoft : COLORS.muted,
                }}
              >
                {day.percent}%
              </div>
            </div>
          );
        })}
      </div>
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
