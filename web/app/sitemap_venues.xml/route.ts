import { getAllVenuesForSitemap } from "@/lib/search/queries";
import { slugify, UNKNOWN_SUBURB_SLUG, venuePath } from "@/lib/search/slugs";
import { siteUrl } from "@/lib/site-url";

// Dynamic: venue list comes from Postgres and changes on sync; CI/Docker
// builds have no database, so this cannot be force-static at image build time.
export const dynamic = "force-dynamic";

function venueSlugKey(suburbName: string | null, venueName: string): string {
  const suburbSlug = suburbName ? slugify(suburbName) : UNKNOWN_SUBURB_SLUG;
  return `${suburbSlug}/${slugify(venueName)}`;
}

function filterUniqueVenueSlugs(
  venues: Awaited<ReturnType<typeof getAllVenuesForSitemap>>,
) {
  const counts = new Map<string, number>();
  for (const row of venues) {
    const key = venueSlugKey(row.suburbName, row.name);
    counts.set(key, (counts.get(key) ?? 0) + 1);
  }

  return venues.filter(
    (row) => counts.get(venueSlugKey(row.suburbName, row.name)) === 1,
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
  const venues = filterUniqueVenueSlugs(await getAllVenuesForSitemap());

  const entries = venues.map((row) =>
    urlEntry(
      `${base}${venuePath(row.suburbName, row.name)}`,
      row.lastCrawlDate ?? row.syncedAt,
      "weekly",
      "0.7",
    ),
  );

  const xml = `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${entries.join("\n")}\n</urlset>`;

  return new Response(xml, {
    headers: {
      "Content-Type": "application/xml",
    },
  });
}
