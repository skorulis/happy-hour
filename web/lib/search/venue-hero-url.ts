/**
 * Rewrites a CDN venue hero URL (`/venues/{id}.jpg`) to the 300px thumb
 * (`/venues/{id}-thumb.jpg`). Non-CDN / source URLs are returned unchanged.
 */
export function venueHeroThumbUrl(
  url: string | null | undefined,
): string | null {
  if (!url?.trim()) {
    return null;
  }

  try {
    const parsed = new URL(url);
    const rewritten = parsed.pathname.replace(
      /^(.*\/venues\/\d+)\.jpe?g$/i,
      "$1-thumb.jpg",
    );
    if (rewritten !== parsed.pathname) {
      parsed.pathname = rewritten;
      return parsed.toString();
    }
  } catch {
    // fall through
  }

  return url;
}
