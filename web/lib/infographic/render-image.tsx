import { ImageResponse } from "next/og";
import {
  BEER_GLASS_VIEWBOX,
  buildBeerGlassGeometry,
} from "@/lib/infographic/beer-glass";
import { buildDrinkBarRows } from "@/lib/infographic/drink-bars";
import { buildDayHourHeatGrid } from "@/lib/infographic/day-hour-heat";
import { productIconDataUri, flameIconDataUri } from "@/lib/infographic/drink-icon-data-uri";
import { loadInfographicFonts } from "@/lib/infographic/og-fonts";
import type {
  InfographicComposition,
  InfographicFormat,
  InfographicSlot,
} from "@/lib/infographic/types";
import { INFOGRAPHIC_IMAGE_SIZES } from "@/lib/infographic/types";
import {
  formatDayAbbrev,
  formatHourLabel,
  formatRegionInfographicTitle,
  slotEyebrow,
  slotHeadline,
  slotSupporting,
} from "@/lib/infographic/copy";

const COLORS = {
  pageBg: "#081426",
  cardBg: "#1c202a",
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

/**
 * Satori (next/og) cannot reliably clip SVG via clipPath or render SVG text,
 * so bands are filled paths and the legend is plain HTML.
 */
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
    (glassHeight * BEER_GLASS_VIEWBOX.width) / BEER_GLASS_VIEWBOX.height,
  );

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        gap: compact ? 12 : 16,
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

      <div
        style={{
          display: "flex",
          flexDirection: "row",
          alignItems: "center",
          gap: compact ? 28 : 40,
        }}
      >
        <svg
          width={glassWidth}
          height={glassHeight}
          viewBox={geometry.viewBox}
        >
          {geometry.segments.map((segment) => (
            <path
              key={`seg-${segment.dayOfWeek}`}
              d={segment.pathD}
              fill={segment.color}
            />
          ))}
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
            height: glassHeight,
            paddingTop: 4,
            paddingBottom: 4,
          }}
        >
          {geometry.legend.map((item) => {
            const isPeak = item.dayOfWeek === slot.peakDayOfWeek;
            return (
              <div
                key={`legend-${item.dayOfWeek}`}
                style={{
                  display: "flex",
                  flexDirection: "row",
                  alignItems: "center",
                  gap: 10,
                }}
              >
                <div
                  style={{
                    display: "flex",
                    width: 12,
                    height: 12,
                    backgroundColor: item.color,
                    border:
                      item.color.toLowerCase() === "#f8fafc"
                        ? `1px solid ${COLORS.border}`
                        : "none",
                  }}
                />
                <div
                  style={{
                    display: "flex",
                    fontSize: compact ? 18 : 22,
                    fontWeight: isPeak ? 700 : 500,
                    color: isPeak ? COLORS.fg : COLORS.secondary,
                    letterSpacing: "0.04em",
                    width: 48,
                  }}
                >
                  {item.label}
                </div>
                <div
                  style={{
                    display: "flex",
                    fontSize: compact ? 18 : 22,
                    fontWeight: isPeak ? 700 : 500,
                    color: isPeak ? COLORS.accentSoft : COLORS.muted,
                  }}
                >
                  {`${item.percent}%`}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

function DayHourHeatBlock({
  slot,
  compact,
}: {
  slot: Extract<InfographicSlot, { id: "dayHourHeat" }>;
  compact?: boolean;
}) {
  const grid = buildDayHourHeatGrid(slot.cells);
  const cellSize = compact ? 18 : 22;
  const labelWidth = compact ? 36 : 42;

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        gap: compact ? 12 : 16,
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

      <div
        style={{
          display: "flex",
          flexDirection: "column",
          gap: 4,
        }}
      >
        <div
          style={{
            display: "flex",
            flexDirection: "row",
            gap: 4,
            paddingLeft: labelWidth,
          }}
        >
          {grid.hours.map((hour) => (
            <div
              key={`hh-${hour}`}
              style={{
                display: "flex",
                width: cellSize,
                height: 18,
                alignItems: "flex-end",
                justifyContent: "center",
                fontSize: 11,
                color: COLORS.muted,
              }}
            >
              {hour % 3 === 0 ? formatHourLabel(hour) : ""}
            </div>
          ))}
        </div>
        {grid.days.map((dayOfWeek) => (
          <div
            key={`hd-${dayOfWeek}`}
            style={{
              display: "flex",
              flexDirection: "row",
              alignItems: "center",
              gap: 4,
            }}
          >
            <div
              style={{
                display: "flex",
                width: labelWidth,
                fontSize: compact ? 14 : 16,
                fontWeight: 600,
                color: COLORS.secondary,
              }}
            >
              {formatDayAbbrev(dayOfWeek)}
            </div>
            {grid.hours.map((hour) => {
              const cell = grid.cells.find(
                (entry) =>
                  entry.dayOfWeek === dayOfWeek && entry.hour === hour,
              )!;
              const iconSize = Math.max(10, Math.round(cellSize * 0.7));
              return (
                <div
                  key={`hc-${dayOfWeek}-${hour}`}
                  style={{
                    display: "flex",
                    width: cellSize,
                    height: cellSize,
                    borderRadius: 3,
                    backgroundColor: cell.color,
                    alignItems: "center",
                    justifyContent: "center",
                  }}
                >
                  {cell.isPeak ? (
                    // eslint-disable-next-line @next/next/no-img-element -- inline SVG data URIs for OG image render
                    <img
                      src={flameIconDataUri("#081426", iconSize)}
                      width={iconSize}
                      height={iconSize}
                      alt=""
                    />
                  ) : null}
                </div>
              );
            })}
          </div>
        ))}
      </div>
    </div>
  );
}

function DrinkMixBlock({
  slot,
  compact,
}: {
  slot: Extract<InfographicSlot, { id: "topProducts" }>;
  compact?: boolean;
}) {
  const rows = buildDrinkBarRows(slot.products, {
    maxIcons: compact ? 8 : 12,
  });
  const iconSize = compact ? 16 : 20;

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        gap: compact ? 12 : 16,
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

      <div
        style={{
          display: "flex",
          flexDirection: "column",
          gap: compact ? 10 : 14,
          width: "100%",
        }}
      >
        {rows.map((row) => (
            <div
              key={row.name}
              style={{
                display: "flex",
                flexDirection: "row",
                alignItems: "center",
                gap: compact ? 12 : 16,
                width: "100%",
              }}
            >
              <div
                style={{
                  display: "flex",
                  width: compact ? 110 : 140,
                  fontSize: compact ? 18 : 22,
                  fontWeight: row.isLeader ? 700 : 500,
                  color: row.isLeader ? COLORS.fg : COLORS.secondary,
                  textTransform: "capitalize",
                }}
              >
                {row.name}
              </div>
              <div
                style={{
                  display: "flex",
                  flexDirection: "row",
                  flexWrap: "wrap",
                  alignItems: "center",
                  gap: 2,
                  flexGrow: 1,
                }}
              >
                {Array.from({ length: row.iconCount }, (_, index) => (
                  // eslint-disable-next-line @next/next/no-img-element -- inline SVG data URIs for OG image render
                  <img
                    key={`${row.name}-${index}`}
                    src={productIconDataUri(row.icon, row.color, iconSize)}
                    width={iconSize}
                    height={iconSize}
                    alt=""
                  />
                ))}
              </div>
              <div
                style={{
                  display: "flex",
                  width: compact ? 48 : 56,
                  justifyContent: "flex-end",
                  fontSize: compact ? 18 : 22,
                  fontWeight: row.isLeader ? 700 : 500,
                  color: row.isLeader ? COLORS.accentSoft : COLORS.muted,
                }}
              >
                {`${row.percent}%`}
              </div>
            </div>
          ))}
      </div>
    </div>
  );
}

export async function renderRegionInfographicImage(
  composition: InfographicComposition,
  format: Exclude<InfographicFormat, "page">,
): Promise<ImageResponse> {
  const size = INFOGRAPHIC_IMAGE_SIZES[format];
  const fonts = await loadInfographicFonts();
  const isOg = format === "og";
  const isStory = format === "story";
  const isSquare = format === "square";
  const compact = isOg || isSquare;
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
  const gridColumns = isOg ? 3 : 2;
  const outerPad = isOg ? 24 : isStory ? 44 : 32;
  const innerPad = isStory ? 52 : isOg ? 36 : 44;
  const cardRadius = isOg ? 24 : 32;
  const cardWidth = size.width - outerPad * 2;
  const cardHeight = size.height - outerPad * 2;

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          backgroundColor: COLORS.pageBg,
          fontFamily: "Geist",
        }}
      >
        <div
          style={{
            width: cardWidth,
            height: cardHeight,
            display: "flex",
            flexDirection: "column",
            justifyContent: "flex-start",
            padding: innerPad,
            borderRadius: cardRadius,
            border: `3px solid ${COLORS.border}`,
            overflow: "hidden",
            backgroundColor: COLORS.cardBg,
            backgroundImage:
              "radial-gradient(ellipse 100% 80% at 15% -10%, rgba(124, 58, 87, 0.55) 0%, transparent 55%), radial-gradient(ellipse 70% 50% at 100% 0%, rgba(245, 158, 11, 0.2) 0%, transparent 50%)",
            color: COLORS.fg,
          }}
        >
          <div
            style={{
              display: "flex",
              flexDirection: "column",
              gap: compact ? 10 : 16,
            }}
          >
            <div
              style={{
                display: "flex",
                fontSize: isOg ? 22 : 26,
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
                fontSize: isOg ? 52 : isStory ? 76 : 64,
                fontWeight: 700,
                lineHeight: 1.05,
              }}
            >
              {composition.regionName}
            </div>
            <div
              style={{
                display: "flex",
                fontSize: isOg ? 24 : 28,
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
                gap: 6,
                borderBottom: `2px solid ${COLORS.border}`,
                paddingBottom: compact ? 14 : 20,
                marginTop: compact ? 14 : 22,
              }}
            >
              <SlotBlock
                eyebrow={slotEyebrow(headline)}
                headline={slotHeadline(headline)}
                supporting={slotSupporting(headline)}
                compact={compact}
              />
            </div>
          ) : null}

          {weekdayMix && weekdayMix.id === "weekdayMix" ? (
            <div
              style={{
                display: "flex",
                marginTop: compact ? 16 : 22,
                marginBottom: compact ? 8 : 14,
              }}
            >
              <WeekdayMixBlock slot={weekdayMix} compact={compact} />
            </div>
          ) : null}

          {dayHourHeat && dayHourHeat.id === "dayHourHeat" ? (
            <div
              style={{
                display: "flex",
                marginTop: compact ? 8 : 12,
                marginBottom: compact ? 8 : 12,
              }}
            >
              <DayHourHeatBlock slot={dayHourHeat} compact={compact} />
            </div>
          ) : null}

          {topProducts && topProducts.id === "topProducts" ? (
            <div
              style={{
                display: "flex",
                marginTop: compact ? 8 : 12,
                marginBottom: compact ? 8 : 12,
              }}
            >
              <DrinkMixBlock slot={topProducts} compact={compact} />
            </div>
          ) : null}

          <div
            style={{
              display: "flex",
              flexWrap: "wrap",
              gap: compact ? 20 : 28,
              marginTop: compact ? 8 : 12,
              alignContent: "flex-start",
            }}
          >
            {rest.map((slot) => (
              <div
                key={slot.id}
                style={{
                  display: "flex",
                  width: `${100 / gridColumns - 2}%`,
                  minWidth: isOg ? 180 : 240,
                }}
              >
                <SlotBlock
                  eyebrow={slotEyebrow(slot)}
                  headline={slotHeadline(slot)}
                  supporting={slotSupporting(slot)}
                  compact={compact}
                />
              </div>
            ))}
          </div>
        </div>
      </div>
    ),
    {
      ...size,
      fonts,
      headers: {
        "Cache-Control": "public, s-maxage=3600, stale-while-revalidate=86400",
      },
    },
  );
}

