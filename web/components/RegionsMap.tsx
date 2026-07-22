"use client";

import { useRouter } from "next/navigation";
import { useCallback, useMemo, useState, type KeyboardEvent } from "react";
import {
  buildOutlinePaths,
  buildRegionPaths,
  createAustraliaProjection,
  MAP_HEIGHT,
  MAP_WIDTH,
} from "@/lib/regions/map-projection";
import {
  formatRegionMapLabel,
  regionBySlug,
  regionMapHref,
  type RegionMapItem,
} from "@/lib/regions/map-data";

type RegionsMapProps = {
  regions: RegionMapItem[];
};

const OUTLINE_FILL = "transparent";
const OUTLINE_STROKE = "var(--color-border, #404040)";
const REGION_FILL = "var(--color-accent-muted, #3d2f4a)";
const REGION_STROKE = "var(--color-accent-soft, #9b7bb8)";
const REGION_HOVER_FILL = "var(--color-accent, #7c5cbf)";
const REGION_FOCUS_STROKE = "var(--color-accent-fg, #ffffff)";

export function RegionsMap({ regions }: RegionsMapProps) {
  const router = useRouter();
  const regionsBySlug = useMemo(() => regionBySlug(regions), [regions]);
  const projection = useMemo(() => createAustraliaProjection(), []);
  const outlinePaths = useMemo(
    () => buildOutlinePaths(projection),
    [projection],
  );
  const regionPaths = useMemo(() => buildRegionPaths(projection), [projection]);

  const [hoveredSlug, setHoveredSlug] = useState<string | null>(null);
  const [focusedSlug, setFocusedSlug] = useState<string | null>(null);

  const activeSlug = hoveredSlug ?? focusedSlug;
  const activeRegion = activeSlug ? regionsBySlug.get(activeSlug) : undefined;

  const navigateToRegion = useCallback(
    (slug: string) => {
      const region = regionsBySlug.get(slug);
      if (!region) {
        return;
      }
      router.push(regionMapHref(region));
    },
    [regionsBySlug, router],
  );

  const handleKeyDown = useCallback(
    (slug: string, event: KeyboardEvent) => {
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault();
        navigateToRegion(slug);
      }
    },
    [navigateToRegion],
  );

  return (
    <div className="space-y-3">
      <p className="text-sm text-muted">
        Select a region on the map, or use the list below.
      </p>

      <div className="relative w-full overflow-hidden">
        {activeRegion ? (
          <div
            className="pointer-events-none absolute left-3 top-3 z-10 rounded-lg border border-border bg-background/95 px-3 py-2 text-sm shadow-sm"
            aria-hidden
          >
            <p className="font-medium text-foreground">{activeRegion.name}</p>
            <p className="text-muted">
              {activeRegion.venueCount}{" "}
              {activeRegion.venueCount === 1 ? "venue" : "venues"} ·{" "}
              {activeRegion.dealCount}{" "}
              {activeRegion.dealCount === 1 ? "deal" : "deals"}
            </p>
          </div>
        ) : null}

        <div className="aspect-[4/3] w-full max-h-[28rem]">
          <svg
            viewBox={`0 0 ${MAP_WIDTH} ${MAP_HEIGHT}`}
            className="h-full w-full"
            role="presentation"
          >
            {outlinePaths.map((path, index) => (
              <path
                key={`outline-${index}`}
                d={path}
                fill={OUTLINE_FILL}
                stroke={OUTLINE_STROKE}
                strokeWidth={0.5}
                fillRule="evenodd"
              />
            ))}

            {regionPaths.map(({ slug, path }) => {
              if (!slug || !regionsBySlug.has(slug)) {
                return null;
              }

              const region = regionsBySlug.get(slug)!;
              const isActive = activeSlug === slug;
              const label = formatRegionMapLabel(region);

              return (
                <path
                  key={slug}
                  d={path}
                  tabIndex={0}
                  role="link"
                  aria-label={label}
                  className="region-map-geography"
                  fill={isActive ? REGION_HOVER_FILL : REGION_FILL}
                  stroke={isActive ? REGION_FOCUS_STROKE : REGION_STROKE}
                  strokeWidth={isActive ? 1.25 : 0.75}
                  fillRule="evenodd"
                  style={{ cursor: "pointer", transition: "fill 150ms ease" }}
                  onMouseEnter={() => setHoveredSlug(slug)}
                  onMouseLeave={() =>
                    setHoveredSlug((current) => (current === slug ? null : current))
                  }
                  onFocus={() => setFocusedSlug(slug)}
                  onBlur={() =>
                    setFocusedSlug((current) => (current === slug ? null : current))
                  }
                  onClick={() => navigateToRegion(slug)}
                  onKeyDown={(event) => handleKeyDown(slug, event)}
                />
              );
            })}
          </svg>
        </div>
      </div>
    </div>
  );
}
