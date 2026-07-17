import { getAllSuburbsForSitemap } from "@/lib/search/queries";
import { suburbWherePath, suburbWhereSlug } from "@/lib/search/slugs";
import { siteUrl } from "@/lib/site-url";

// Dynamic: suburb list comes from Postgres; CI/Docker builds have no
// database, so this cannot be force-static at image build time.
export const dynamic = "force-dynamic";

function filterUniqueSuburbSlugs(
  suburbs: Awaited<ReturnType<typeof getAllSuburbsForSitemap>>,
) {
  const counts = new Map<string, number>();
  for (const row of suburbs) {
    const key = suburbWhereSlug(row.name, row.postcode);
    counts.set(key, (counts.get(key) ?? 0) + 1);
  }

  return suburbs.filter(
    (row) => counts.get(suburbWhereSlug(row.name, row.postcode)) === 1,
  );
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
  const suburbs = filterUniqueSuburbSlugs(await getAllSuburbsForSitemap());
  const lastmod = new Date();

  const entries = suburbs.map((row) =>
    urlEntry(
      `${base}${suburbWherePath(row.name, row.postcode)}`,
      lastmod,
      "weekly",
      "0.8",
    ),
  );

  const xml = `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${entries.join("\n")}\n</urlset>`;

  return new Response(xml, {
    headers: {
      "Content-Type": "application/xml",
    },
  });
}
