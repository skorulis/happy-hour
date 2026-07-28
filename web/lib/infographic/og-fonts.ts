import { readFile } from "node:fs/promises";
import { join } from "node:path";
import type { ImageResponse } from "next/og";

type OgFont = NonNullable<
  NonNullable<ConstructorParameters<typeof ImageResponse>[1]>["fonts"]
>[number];

const GEIST_CDN = {
  400: "https://cdn.jsdelivr.net/fontsource/fonts/geist-sans@5.2.5/latin-400-normal.woff",
  600: "https://cdn.jsdelivr.net/fontsource/fonts/geist-sans@5.2.5/latin-600-normal.woff",
  700: "https://cdn.jsdelivr.net/fontsource/fonts/geist-sans@5.2.5/latin-700-normal.woff",
} as const;

let fontsPromise: Promise<OgFont[]> | null = null;

async function fetchFont(url: string): Promise<ArrayBuffer> {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Failed to fetch font (${response.status}): ${url}`);
  }
  return response.arrayBuffer();
}

async function loadBundledGeistRegular(): Promise<ArrayBuffer> {
  const path = join(
    process.cwd(),
    "node_modules/next/dist/compiled/@vercel/og/Geist-Regular.ttf",
  );
  const buffer = await readFile(path);
  return buffer.buffer.slice(
    buffer.byteOffset,
    buffer.byteOffset + buffer.byteLength,
  );
}

/**
 * Load Geist (site sans) for ImageResponse. Cached per process.
 * Falls back to Next’s bundled Geist Regular if the CDN is unreachable.
 */
export async function loadInfographicFonts(): Promise<OgFont[]> {
  if (!fontsPromise) {
    fontsPromise = (async () => {
      try {
        const [regular, semibold, bold] = await Promise.all([
          fetchFont(GEIST_CDN[400]),
          fetchFont(GEIST_CDN[600]),
          fetchFont(GEIST_CDN[700]),
        ]);
        return [
          { name: "Geist", data: regular, weight: 400, style: "normal" },
          { name: "Geist", data: semibold, weight: 600, style: "normal" },
          { name: "Geist", data: bold, weight: 700, style: "normal" },
        ];
      } catch {
        const regular = await loadBundledGeistRegular();
        return [
          { name: "Geist", data: regular, weight: 400, style: "normal" },
          { name: "Geist", data: regular, weight: 600, style: "normal" },
          { name: "Geist", data: regular, weight: 700, style: "normal" },
        ];
      }
    })();
  }
  return fontsPromise;
}
