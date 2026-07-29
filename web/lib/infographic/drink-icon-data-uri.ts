type IconElement =
  | { tag: "path"; d: string }
  | { tag: "circle"; cx: number; cy: number; r: number }
  | {
      tag: "rect";
      x: number;
      y: number;
      width: number;
      height: number;
      rx?: number;
    };

/** Lucide 24×24 stroke elements for product icons used in OG/download cards. */
const STROKE_ICONS: Record<string, IconElement[]> = {
  Beer: [
    { tag: "path", d: "M17 11h1a3 3 0 0 1 0 6h-1" },
    { tag: "path", d: "M9 12v6" },
    { tag: "path", d: "M13 12v6" },
    {
      tag: "path",
      d: "M14 7.5c-1 0-1.44.5-3 .5s-2-.5-3-.5-1.72.5-2.5.5a2.5 2.5 0 0 1 0-5c.78 0 1.57.5 2.5.5S9.44 2 11 2s2 1.5 3 1.5 1.72-.5 2.5-.5a2.5 2.5 0 0 1 0 5c-.78 0-1.5-.5-2.5-.5Z",
    },
    { tag: "path", d: "M5 8v12a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V8" },
  ],
  Wine: [
    { tag: "path", d: "M8 22h8" },
    { tag: "path", d: "M7 10h10" },
    { tag: "path", d: "M12 15v7" },
    {
      tag: "path",
      d: "M12 15a5 5 0 0 0 5-5c0-2-.5-4-2-8H9c-1.5 4-2 6-2 8a5 5 0 0 0 5 5Z",
    },
  ],
  Martini: [
    {
      tag: "path",
      d: "M12 12 4.207 4.207A.707.707 0 0 1 4.707 3h14.586a.707.707 0 0 1 .5 1.207z",
    },
    { tag: "path", d: "M12 12v10" },
    { tag: "path", d: "M7 22h10" },
  ],
  BottleWine: [
    {
      tag: "path",
      d: "M10 3a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v2a6 6 0 0 0 1.2 3.6l.6.8A6 6 0 0 1 17 13v8a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1v-8a6 6 0 0 1 1.2-3.6l.6-.8A6 6 0 0 0 10 5z",
    },
    {
      tag: "path",
      d: "M17 13h-4a1 1 0 0 0-1 1v3a1 1 0 0 0 1 1h4",
    },
  ],
  Flame: [
    {
      tag: "path",
      d: "M12 3q1 4 4 6.5t3 5.5a1 1 0 0 1-14 0 5 5 0 0 1 1-3 1 1 0 0 0 5 0c0-2-1.5-3-1.5-5q0-2 2.5-4",
    },
  ],
  UtensilsCrossed: [
    {
      tag: "path",
      d: "m16 2-2.3 2.3a3 3 0 0 0 0 4.2l1.8 1.8a3 3 0 0 0 4.2 0L22 8",
    },
    {
      tag: "path",
      d: "M15 15 3.3 3.3a4.2 4.2 0 0 0 0 6l7.3 7.3c.7.7 2 .7 2.8 0L15 15Zm0 0 7 7",
    },
    { tag: "path", d: "m2.1 21.8 6.4-6.3" },
    { tag: "path", d: "m19 5-7 7" },
  ],
  Pizza: [
    { tag: "path", d: "m12 14-1 1" },
    { tag: "path", d: "m13.75 18.25-1.25 1.42" },
    {
      tag: "path",
      d: "M17.775 5.654a15.68 15.68 0 0 0-12.121 12.12",
    },
    { tag: "path", d: "M18.8 9.3a1 1 0 0 0 2.1 7.7" },
    {
      tag: "path",
      d: "M21.964 20.732a1 1 0 0 1-1.232 1.232l-18-5a1 1 0 0 1-.695-1.232A19.68 19.68 0 0 1 15.732 2.037a1 1 0 0 1 1.232.695z",
    },
  ],
  Fish: [
    {
      tag: "path",
      d: "M6.5 12c.94-3.46 4.94-6 8.5-6 3.56 0 6.06 2.54 7 6-.94 3.47-3.44 6-7 6s-7.56-2.53-8.5-6Z",
    },
    { tag: "path", d: "M18 12v.5" },
    { tag: "path", d: "M16 17.93a9.77 9.77 0 0 1 0-11.86" },
    {
      tag: "path",
      d: "M7 10.67C7 8 5.58 5.97 2.73 5.5c-1 1.5-1 5 .23 6.5-1.24 1.5-1.24 5-.23 6.5C5.58 18.03 7 16 7 13.33",
    },
    {
      tag: "path",
      d: "M10.46 7.26C10.2 5.88 9.17 4.24 8 3h5.8a2 2 0 0 1 1.98 1.67l.23 1.4",
    },
    {
      tag: "path",
      d: "m16.01 17.93-.23 1.4A2 2 0 0 1 13.8 21H9.5a5.96 5.96 0 0 0 1.49-3.98",
    },
  ],
  Beef: [
    {
      tag: "path",
      d: "M16.4 13.7A6.5 6.5 0 1 0 6.28 6.6c-1.1 3.13-.78 3.9-3.18 6.08A3 3 0 0 0 5 18c4 0 8.4-1.8 11.4-4.3",
    },
    {
      tag: "path",
      d: "m18.5 6 2.19 4.5a6.48 6.48 0 0 1-2.29 7.2C15.4 20.2 11 22 7 22a3 3 0 0 1-2.68-1.66L2.4 16.5",
    },
    { tag: "circle", cx: 12.5, cy: 8.5, r: 2.5 },
  ],
  Salad: [
    { tag: "path", d: "M7 21h10" },
    { tag: "path", d: "M12 21a9 9 0 0 0 9-9H3a9 9 0 0 0 9 9Z" },
    {
      tag: "path",
      d: "M11.38 12a2.4 2.4 0 0 1-.4-4.77 2.4 2.4 0 0 1 3.2-2.77 2.4 2.4 0 0 1 3.47-.63 2.4 2.4 0 0 1 3.37 3.37 2.4 2.4 0 0 1-1.1 3.7 2.51 2.51 0 0 1 .03 1.1",
    },
    { tag: "path", d: "m13 12 4-4" },
    {
      tag: "path",
      d: "M10.9 7.25A3.99 3.99 0 0 0 4 10c0 .73.2 1.41.54 2",
    },
  ],
  Soup: [
    { tag: "path", d: "M12 21a9 9 0 0 0 9-9H3a9 9 0 0 0 9 9Z" },
    { tag: "path", d: "M7 21h10" },
    { tag: "path", d: "M19.5 12 22 6" },
    {
      tag: "path",
      d: "M16.25 3c.27.1.8.53.75 1.36-.06.83-.93 1.2-1 2.02-.05.78.34 1.24.73 1.62",
    },
    {
      tag: "path",
      d: "M11.25 3c.27.1.8.53.74 1.36-.05.83-.93 1.2-.98 2.02-.06.78.33 1.24.72 1.62",
    },
    {
      tag: "path",
      d: "M6.25 3c.27.1.8.53.75 1.36-.06.83-.93 1.2-1 2.02-.05.78.34 1.24.74 1.62",
    },
  ],
  Sandwich: [
    {
      tag: "path",
      d: "m2.37 11.223 8.372-6.777a2 2 0 0 1 2.516 0l8.371 6.777",
    },
    { tag: "path", d: "M21 15a1 1 0 0 1 1 1v2a1 1 0 0 1-1 1h-5.25" },
    { tag: "path", d: "M3 15a1 1 0 0 0-1 1v2a1 1 0 0 0 1 1h9" },
    {
      tag: "path",
      d: "m6.67 15 6.13 4.6a2 2 0 0 0 2.8-.4l3.15-4.2",
    },
    { tag: "rect", width: 20, height: 4, x: 2, y: 11, rx: 1 },
  ],
  Drumstick: [
    {
      tag: "path",
      d: "M15.4 15.63a7.875 6 135 1 1 6.23-6.23 4.5 3.43 135 0 0-6.23 6.23",
    },
    {
      tag: "path",
      d: "m8.29 12.71-2.6 2.6a2.5 2.5 0 1 0-1.65 4.65A2.5 2.5 0 1 0 8.7 18.3l2.59-2.59",
    },
  ],
  ChartPie: [
    {
      tag: "path",
      d: "M21 12c.552 0 1.005-.449.95-.998a10 10 0 0 0-8.953-8.951c-.55-.055-.998.398-.998.95v8a1 1 0 0 0 1 1z",
    },
    { tag: "path", d: "M21.21 15.89A10 10 0 1 1 8 2.83" },
  ],
  CookingPot: [
    { tag: "path", d: "M2 12h20" },
    { tag: "path", d: "M20 12v8a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2v-8" },
    { tag: "path", d: "m4 8 16-4" },
    {
      tag: "path",
      d: "m8.86 6.78-.45-1.81a2 2 0 0 1 1.45-2.43l1.94-.48a2 2 0 0 1 2.43 1.46l.45 1.8",
    },
  ],
};

/** Custom / map icons → closest Lucide stroke stand-in for Satori cards. */
const ICON_ALIASES: Record<string, keyof typeof STROKE_ICONS> = {
  Whisky: "BottleWine",
  Sake: "Wine",
  Soju: "BottleWine",
  Wings: "Drumstick",
  Burger: "Sandwich",
  HotDog: "Sandwich",
  Nachos: "UtensilsCrossed",
  Cheese: "UtensilsCrossed",
  Taco: "UtensilsCrossed",
  Sausage: "Drumstick",
  Ham: "Beef",
  Kebab: "Drumstick",
  PaperBag: "UtensilsCrossed",
  EggFried: "UtensilsCrossed",
  LunchBox: "UtensilsCrossed",
};

const cache = new Map<string, string>();

const STROKE_ATTRS =
  'fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"';

function renderIconElement(element: IconElement, color: string): string {
  const stroke = `stroke="${color}" ${STROKE_ATTRS}`;
  switch (element.tag) {
    case "path":
      return `<path d="${element.d}" ${stroke}/>`;
    case "circle":
      return `<circle cx="${element.cx}" cy="${element.cy}" r="${element.r}" ${stroke}/>`;
    case "rect":
      return `<rect x="${element.x}" y="${element.y}" width="${element.width}" height="${element.height}"${
        element.rx != null ? ` rx="${element.rx}"` : ""
      } ${stroke}/>`;
  }
}

function resolveStrokeIcon(
  iconName: string | undefined,
  fallback: keyof typeof STROKE_ICONS,
): IconElement[] {
  if (!iconName) return STROKE_ICONS[fallback]!;
  if (iconName in STROKE_ICONS) return STROKE_ICONS[iconName]!;
  const alias = ICON_ALIASES[iconName];
  if (alias) return STROKE_ICONS[alias]!;
  return STROKE_ICONS[fallback]!;
}

/**
 * Satori-friendly product icon as a data URI (no react-dom/server).
 * Poster still uses live Lucide via ProductMapIcon.
 */
export function productIconDataUri(
  iconName: string | undefined,
  color: string,
  size: number,
  fallbackIcon: keyof typeof STROKE_ICONS = "Beer",
): string {
  const cacheKey = `${iconName ?? fallbackIcon}:${fallbackIcon}:${color}:${size}`;
  const cached = cache.get(cacheKey);
  if (cached) return cached;

  const elements = resolveStrokeIcon(iconName, fallbackIcon)
    .map((element) => renderIconElement(element, color))
    .join("");
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 24 24">${elements}</svg>`;
  const uri = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`;
  cache.set(cacheKey, uri);
  return uri;
}

/** Lucide Flame mark for the peak heat-map cell in share images. */
export function flameIconDataUri(color: string, size: number): string {
  return productIconDataUri("Flame", color, size);
}
