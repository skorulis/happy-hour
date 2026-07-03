import type { MetadataRoute } from "next";
import { siteUrl } from "@/lib/site-url";

export default function robots(): MetadataRoute.Robots {
  const base = siteUrl();

  return {
    rules: {
      userAgent: "*",
      allow: "/",
      disallow: ["/favourites", "/venue-search", "/venues/"],
    },
    sitemap: `${base}/sitemap.xml`,
  };
}
