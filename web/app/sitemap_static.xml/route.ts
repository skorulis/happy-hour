import { siteUrl } from "@/lib/site-url";

export const dynamic = "force-static";

function escapeXml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

function urlEntry(
  loc: string,
  lastmod: Date,
  changefreq: string,
  priority: string,
): string {
  return `<url><loc>${escapeXml(loc)}</loc><lastmod>${lastmod.toISOString()}</lastmod><changefreq>${changefreq}</changefreq><priority>${priority}</priority></url>`;
}

export function GET() {
  const base = siteUrl();
  const now = new Date();
  const entries = [
    urlEntry(base, now, "daily", "1.0"),
    urlEntry(`${base}/map`, now, "daily", "0.9"),
    urlEntry(`${base}/all-suburbs`, now, "daily", "0.8"),
    urlEntry(`${base}/venue-search`, now, "daily", "0.7"),
    urlEntry(`${base}/about`, now, "monthly", "0.5"),
    urlEntry(`${base}/privacy`, now, "monthly", "0.4"),
  ];

  const xml = `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${entries.join("\n")}\n</urlset>`;

  return new Response(xml, {
    headers: {
      "Content-Type": "application/xml",
    },
  });
}
