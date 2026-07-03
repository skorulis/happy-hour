/**
 * Canonical site origin for absolute URLs (sitemap, robots, metadataBase).
 * No trailing slash — callers append paths like `${siteUrl()}/sitemap.xml`.
 */
export function siteUrl(): string {
  const explicit = process.env.NEXT_PUBLIC_SITE_URL?.trim();
  if (explicit) {
    return explicit.replace(/\/+$/, "");
  }

  const vercelHost = process.env.VERCEL_PROJECT_PRODUCTION_URL?.trim();
  if (vercelHost) {
    return `https://${vercelHost.replace(/\/+$/, "")}`;
  }

  return "http://localhost:3000";
}
