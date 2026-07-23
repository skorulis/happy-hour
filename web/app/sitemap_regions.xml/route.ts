import { getAllRegionsForSitemap } from "@/lib/search/queries";
import { regionPath, regionSlug } from "@/lib/search/slugs";
import { siteUrl } from "@/lib/site-url";

// Dynamic: region list comes from Postgres; CI/Docker builds have no
// database, so this cannot be force-static at image build time.
export const dynamic = "force-dynamic";

function filterUniqueRegionSlugs(
  regions: Awaited<ReturnType<typeof getAllRegionsForSitemap>>,
) {
  const counts = new Map<string, number>();
  for (const row of regions) {
    const key = regionSlug(row.name);
    counts.set(key, (counts.get(key) ?? 0) + 1);
  }

  return regions.filter((row) => counts.get(regionSlug(row.name)) === 1);
}

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

export async function GET() {
  const base = siteUrl();
  const regions = filterUniqueRegionSlugs(await getAllRegionsForSitemap());
  const lastmod = new Date();

  const entries = regions.map((row) =>
    urlEntry(`${base}${regionPath(row.name)}`, lastmod, "weekly", "0.9"),
  );

  const xml = `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${entries.join("\n")}\n</urlset>`;

  return new Response(xml, {
    headers: {
      "Content-Type": "application/xml",
    },
  });
}
