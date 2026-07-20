import { siteUrl } from "@/lib/site-url";

export const dynamic = "force-static";

export function GET() {
  const base = siteUrl();
  const lastmod = new Date().toISOString();

  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
<sitemap><loc>${base}/sitemap_static.xml</loc><lastmod>${lastmod}</lastmod></sitemap>
<sitemap><loc>${base}/sitemap_venues.xml</loc><lastmod>${lastmod}</lastmod></sitemap>
<sitemap><loc>${base}/sitemap_suburbs.xml</loc><lastmod>${lastmod}</lastmod></sitemap>
</sitemapindex>`;

  return new Response(xml, {
    headers: {
      "Content-Type": "application/xml",
    },
  });
}
