import { ImageResponse } from "next/og";
import {
  BEER_GLASS_VIEWBOX,
  buildBeerGlassGeometry,
} from "@/lib/infographic/beer-glass";
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
} from "@/lib/infographic/coverage-rings";
import {
  buildDensityBarRows,
  formatDensityBarValue,
} from "@/lib/infographic/density-bars";
import { buildDrinkBarRows } from "@/lib/infographic/drink-bars";
import { buildDayHourHeatGrid } from "@/lib/infographic/day-hour-heat";
import { productIconDataUri, flameIconDataUri } from "@/lib/infographic/drink-icon-data-uri";
import { loadInfographicFonts } from "@/lib/infographic/og-fonts";
import type {
  CoverageTriadRing,
  InfographicComposition,
  InfographicFormat,
  InfographicSlot,
} from "@/lib/infographic/types";
import { INFOGRAPHIC_IMAGE_SIZES } from "@/lib/infographic/types";
import {
  formatCoveragePercent,
  formatDayAbbrev,
  formatDealCount,
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

function CoverageRingBlock({
  ring,
  size,
}: {
  ring: CoverageTriadRing;
  size: number;
}) {
  const dash = coverageRingDash(ring.percent);
  const percentLabel = formatCoveragePercent(
    clampCoveragePercent(ring.percent),
  );
  const unit = coverageRingScaleUnitLabel(ring.scaleUnit, ring.scaleCount);

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: 6,
        width: "33%",
        minWidth: 0,
      }}
    >
      <div
        style={{
          display: "flex",
          fontSize: size < 110 ? 13 : 16,
          fontWeight: 600,
          letterSpacing: "0.12em",
          textTransform: "uppercase",
          color: COLORS.accentSoft,
          textAlign: "center",
        }}
      >
        {coverageRingEyebrow(ring)}
      </div>
      <div
        style={{
          display: "flex",
          position: "relative",
          width: size,
          height: size,
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <svg
          width={size}
          height={size}
          viewBox={`0 0 ${COVERAGE_RING_VIEWBOX} ${COVERAGE_RING_VIEWBOX}`}
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
        <div
          style={{
            display: "flex",
            position: "absolute",
            inset: 0,
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <div
            style={{
              display: "flex",
              fontSize: size > 140 ? 36 : size > 110 ? 28 : 22,
              fontWeight: 700,
              color: COLORS.fg,
              lineHeight: 1,
            }}
          >
            {formatDealCount(ring.scaleCount)}
          </div>
          <div
            style={{
              display: "flex",
              fontSize: size < 110 ? 11 : 14,
              fontWeight: 600,
              letterSpacing: "0.08em",
              textTransform: "uppercase",
              color: COLORS.secondary,
              marginTop: 4,
            }}
          >
            {unit}
          </div>
          <div
            style={{
              display: "flex",
              fontSize: size < 110 ? 14 : 18,
              fontWeight: 600,
              color: COLORS.accentSoft,
              marginTop: 4,
            }}
          >
            {percentLabel}
          </div>
        </div>
      </div>
    </div>
  );
}

function CoverageTriadBlock({
  slot,
  compact,
  dense,
}: {
  slot: Extract<InfographicSlot, { id: "coverageTriad" }>;
  compact?: boolean;
  dense?: boolean;
}) {
  const ringSize = dense ? 92 : compact ? 128 : 156;
  const single = slot.rings.length === 1;
  return (
    <div
      style={{
        display: "flex",
        flexDirection: "row",
        width: "100%",
        justifyContent: single ? "center" : "space-between",
        gap: dense ? 8 : compact ? 12 : 20,
      }}
    >
      {slot.rings.map((ring) => (
        <CoverageRingBlock key={ring.id} ring={ring} size={ringSize} />
      ))}
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
    </div>
  );
}

function TopDensityBlock({
  slot,
  compact,
}: {
  slot: Extract<InfographicSlot, { id: "topDensity" }>;
  compact?: boolean;
}) {
  const rows = buildDensityBarRows(slot.suburbs);
  const nameWidth = compact ? 110 : 140;
  const valueWidth = compact ? 72 : 88;
  const labelSize = compact ? 18 : 22;
  const barHeight = compact ? 10 : 12;
  const headlineSize = compact ? 28 : 34;

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
            fontSize: headlineSize,
            fontWeight: 600,
            color: COLORS.secondary,
          }}
        >
          {`${slotHeadline(slot)}${
            slotSupporting(slot) ? ` · ${slotSupporting(slot)}` : ""
          }`}
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
            key={`${row.name}-${row.postcode ?? ""}`}
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
                width: nameWidth,
                fontSize: labelSize,
                fontWeight: row.isLeader ? 700 : 500,
                color: row.isLeader ? COLORS.fg : COLORS.secondary,
              }}
            >
              {row.name}
            </div>
            <div
              style={{
                display: "flex",
                flexGrow: 1,
                height: barHeight,
                borderRadius: 999,
                backgroundColor: "rgba(255,255,255,0.1)",
                overflow: "hidden",
              }}
            >
              <div
                style={{
                  display: "flex",
                  width: `${row.widthPercent}%`,
                  height: "100%",
                  borderRadius: 999,
                  backgroundColor: row.color,
                }}
              />
            </div>
            <div
              style={{
                display: "flex",
                width: valueWidth,
                justifyContent: "flex-end",
                fontSize: labelSize,
                fontWeight: row.isLeader ? 700 : 500,
                color: row.isLeader ? COLORS.accentSoft : COLORS.muted,
              }}
            >
              {formatDensityBarValue(row.value, slot.metric)}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function ProductMixBlock({
  slot,
  compact,
  dense,
  fallbackIcon = "Beer",
}: {
  slot: Extract<InfographicSlot, { id: "topProducts" | "topFood" }>;
  compact?: boolean;
  dense?: boolean;
  fallbackIcon?: "Beer" | "UtensilsCrossed";
}) {
  const rows = buildDrinkBarRows(slot.products, {
    maxIcons: dense ? 6 : compact ? 8 : 12,
  });
  const iconSize = dense ? 14 : compact ? 16 : 20;
  const nameWidth = dense ? 88 : compact ? 110 : 140;
  const percentWidth = dense ? 40 : compact ? 48 : 56;
  const labelSize = dense ? 16 : compact ? 18 : 22;
  const headlineSize = dense ? 22 : compact ? 28 : 34;

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        gap: dense ? 10 : compact ? 12 : 16,
        width: "100%",
      }}
    >
      <div style={{ display: "flex", flexDirection: "column", gap: dense ? 4 : 8 }}>
        <div
          style={{
            display: "flex",
            fontSize: dense ? 16 : compact ? 18 : 22,
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
            fontSize: headlineSize,
            fontWeight: 600,
            color: COLORS.secondary,
          }}
        >
          {`${slotHeadline(slot)}${
            slotSupporting(slot) ? ` · ${slotSupporting(slot)}` : ""
          }`}
        </div>
      </div>

      <div
        style={{
          display: "flex",
          flexDirection: "column",
          gap: dense ? 8 : compact ? 10 : 14,
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
              gap: dense ? 8 : compact ? 12 : 16,
              width: "100%",
            }}
          >
            <div
              style={{
                display: "flex",
                width: nameWidth,
                fontSize: labelSize,
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
                flexGrow: dense ? 0 : 1,
              }}
            >
              {Array.from({ length: row.iconCount }, (_, index) => (
                // eslint-disable-next-line @next/next/no-img-element -- inline SVG data URIs for OG image render
                <img
                  key={`${row.name}-${index}`}
                  src={productIconDataUri(
                    row.icon,
                    row.color,
                    iconSize,
                    fallbackIcon,
                  )}
                  width={iconSize}
                  height={iconSize}
                  alt=""
                />
              ))}
            </div>
            <div
              style={{
                display: "flex",
                width: percentWidth,
                justifyContent: "flex-end",
                marginLeft: dense ? "auto" : 0,
                fontSize: labelSize,
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
  const outerPad = isOg ? 24 : isStory ? 44 : 32;
  const innerPad = isStory ? 52 : isOg ? 36 : 44;
  const cardRadius = isOg ? 24 : 32;
  const cardWidth = size.width - outerPad * 2;
  const cardHeight = size.height - outerPad * 2;
  // OG must fill a fixed social crop. Tall formats hug content so leftover
  // canvas height letterboxes outside the bordered card instead of inside it.
  const cardFillsCanvas = isOg;

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          alignItems: "center",
          justifyContent: cardFillsCanvas ? "center" : "flex-start",
          padding: cardFillsCanvas ? 0 : outerPad,
          backgroundColor: COLORS.pageBg,
          fontFamily: "Geist",
        }}
      >
        <div
          style={{
            width: cardFillsCanvas ? cardWidth : "100%",
            ...(cardFillsCanvas ? { height: cardHeight, overflow: "hidden" } : {}),
            display: "flex",
            flexDirection: "column",
            justifyContent: "flex-start",
            padding: innerPad,
            borderRadius: cardRadius,
            border: `3px solid ${COLORS.border}`,
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
              {formatRegionInfographicTitle(composition.regionName)}
            </div>
          </div>

          {coverageTriad && coverageTriad.id === "coverageTriad" ? (
            <div
              style={{
                display: "flex",
                width: "100%",
                marginTop: compact ? 16 : 22,
                marginBottom: compact ? 8 : 14,
              }}
            >
              <CoverageTriadBlock
                slot={coverageTriad}
                compact={compact}
                dense={isOg}
              />
            </div>
          ) : null}

          {weekdayMix || dayHourHeat ? (
            <div
              style={{
                display: "flex",
                flexDirection:
                  weekdayMix && dayHourHeat ? "row" : "column",
                alignItems: "flex-start",
                gap: compact ? 24 : 32,
                width: "100%",
                marginTop: compact ? 16 : 22,
                marginBottom: compact ? 8 : 14,
              }}
            >
              {weekdayMix && weekdayMix.id === "weekdayMix" ? (
                <div
                  style={{
                    display: "flex",
                    width: dayHourHeat ? "42%" : "100%",
                    flexShrink: 0,
                  }}
                >
                  <WeekdayMixBlock slot={weekdayMix} compact={compact} />
                </div>
              ) : null}
              {dayHourHeat && dayHourHeat.id === "dayHourHeat" ? (
                <div
                  style={{
                    display: "flex",
                    flex: 1,
                    minWidth: 0,
                    marginTop:
                      weekdayMix && dayHourHeat
                        ? compact
                          ? 40
                          : 56
                        : 0,
                  }}
                >
                  <DayHourHeatBlock slot={dayHourHeat} compact={compact} />
                </div>
              ) : null}
            </div>
          ) : null}

          {topProducts || topFood ? (
            <div
              style={{
                display: "flex",
                flexDirection:
                  topProducts && topFood ? "row" : "column",
                alignItems: "flex-start",
                gap: compact ? 20 : 28,
                width: "100%",
                marginTop: compact ? 8 : 12,
                marginBottom: compact ? 8 : 12,
              }}
            >
              {topProducts && topProducts.id === "topProducts" ? (
                <div
                  style={{
                    display: "flex",
                    width: topFood ? "48%" : "100%",
                    flexShrink: 0,
                  }}
                >
                  <ProductMixBlock
                    slot={topProducts}
                    compact={compact}
                    dense={Boolean(topFood)}
                  />
                </div>
              ) : null}
              {topFood && topFood.id === "topFood" ? (
                <div
                  style={{
                    display: "flex",
                    width: topProducts ? "48%" : "100%",
                    flexShrink: 0,
                  }}
                >
                  <ProductMixBlock
                    slot={topFood}
                    compact={compact}
                    dense={Boolean(topProducts)}
                    fallbackIcon="UtensilsCrossed"
                  />
                </div>
              ) : null}
            </div>
          ) : null}

          {topDensity && topDensity.id === "topDensity" ? (
            <div
              style={{
                display: "flex",
                width: "100%",
                marginTop: compact ? 8 : 12,
              }}
            >
              <TopDensityBlock slot={topDensity} compact={compact} />
            </div>
          ) : null}

          <div
            style={{
              display: "flex",
              width: "100%",
              justifyContent: "flex-end",
              marginTop: compact ? 16 : 24,
            }}
          >
            <div
              style={{
                display: "flex",
                fontSize: isOg ? 18 : 22,
                fontWeight: 600,
                letterSpacing: "0.22em",
                textTransform: "uppercase",
                color: COLORS.accentSoft,
              }}
            >
              DuskRoute
            </div>
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

