type IconPaths = string[];

/** Lucide 24×24 stroke paths for drink icons used in OG/download cards. */
const STROKE_ICONS: Record<string, IconPaths> = {
  Beer: [
    "M17 11h1a3 3 0 0 1 0 6h-1",
    "M9 12v6",
    "M13 12v6",
    "M14 7.5c-1 0-1.44.5-3 .5s-2-.5-3-.5-1.72.5-2.5.5a2.5 2.5 0 0 1 0-5c.78 0 1.57.5 2.5.5S9.44 2 11 2s2 1.5 3 1.5 1.72-.5 2.5-.5a2.5 2.5 0 0 1 0 5c-.78 0-1.5-.5-2.5-.5Z",
    "M5 8v12a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V8",
  ],
  Wine: [
    "M8 22h8",
    "M7 10h10",
    "M12 15v7",
    "M12 15a5 5 0 0 0 5-5c0-2-.5-4-2-8H9c-1.5 4-2 6-2 8a5 5 0 0 0 5 5Z",
  ],
  Martini: [
    "M12 12 4.207 4.207A.707.707 0 0 1 4.707 3h14.586a.707.707 0 0 1 .5 1.207z",
    "M12 12v10",
    "M7 22h10",
  ],
  BottleWine: [
    "M10 3a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v2a6 6 0 0 0 1.2 3.6l.6.8A6 6 0 0 1 17 13v8a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1v-8a6 6 0 0 1 1.2-3.6l.6-.8A6 6 0 0 0 10 5z",
    "M17 13h-4a1 1 0 0 0-1 1v3a1 1 0 0 0 1 1h4",
  ],
  Flame: [
    "M12 3q1 4 4 6.5t3 5.5a1 1 0 0 1-14 0 5 5 0 0 1 1-3 1 1 0 0 0 5 0c0-2-1.5-3-1.5-5q0-2 2.5-4",
  ],
};

/** Custom filled icons → closest Lucide stroke stand-in for Satori cards. */
const ICON_ALIASES: Record<string, keyof typeof STROKE_ICONS> = {
  Whisky: "BottleWine",
  Sake: "Wine",
  Soju: "BottleWine",
};

const cache = new Map<string, string>();

function resolveStrokeIcon(iconName: string | undefined): IconPaths {
  if (!iconName) return STROKE_ICONS.Beer!;
  if (iconName in STROKE_ICONS) return STROKE_ICONS[iconName]!;
  const alias = ICON_ALIASES[iconName];
  if (alias) return STROKE_ICONS[alias]!;
  return STROKE_ICONS.Beer!;
}

/**
 * Satori-friendly drink icon as a data URI (no react-dom/server).
 * Poster still uses live Lucide via ProductMapIcon.
 */
export function productIconDataUri(
  iconName: string | undefined,
  color: string,
  size: number,
): string {
  const cacheKey = `${iconName ?? "Beer"}:${color}:${size}`;
  const cached = cache.get(cacheKey);
  if (cached) return cached;

  const paths = resolveStrokeIcon(iconName)
    .map(
      (d) =>
        `<path d="${d}" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>`,
    )
    .join("");
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 24 24">${paths}</svg>`;
  const uri = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`;
  cache.set(cacheKey, uri);
  return uri;
}

/** Lucide Flame mark for the peak heat-map cell in share images. */
export function flameIconDataUri(color: string, size: number): string {
  return productIconDataUri("Flame", color, size);
}
