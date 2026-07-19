/**
 * Rewrites a CDN venue hero URL (`/venues/{id}.jpg`) to the 300px thumb
 * (`/venues/{id}-thumb.jpg`). Non-CDN / source URLs are returned unchanged.
 */
export function venueHeroThumbUrl(
  url: string | null | undefined,
): string | null {
  return heroThumbUrl(url, "venues");
}

/**
 * Rewrites a CDN suburb hero URL (`/suburbs/{id}.jpg`) to the 300px thumb
 * (`/suburbs/{id}-thumb.jpg`). Non-CDN / source URLs are returned unchanged.
 */
export function suburbHeroThumbUrl(
  url: string | null | undefined,
): string | null {
  return heroThumbUrl(url, "suburbs");
}

function heroThumbUrl(
  url: string | null | undefined,
  folder: "venues" | "suburbs",
): string | null {
  if (!url?.trim()) {
    return null;
  }

  try {
    const parsed = new URL(url);
    const pattern = new RegExp(`^(.*\\/${folder}\\/\\d+)\\.jpe?g$`, "i");
    const rewritten = parsed.pathname.replace(pattern, "$1-thumb.jpg");
    if (rewritten !== parsed.pathname) {
      parsed.pathname = rewritten;
      return parsed.toString();
    }
  } catch {
    // fall through
  }

  return url;
}
