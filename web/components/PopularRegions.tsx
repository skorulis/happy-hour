import Link from "next/link";
import type { RegionWithCounts } from "@/lib/search/queries";
import { regionPath } from "@/lib/search/slugs";
import { regionHeroThumbUrl } from "@/lib/search/venue-hero-url";

type PopularRegionsProps = {
  regions: RegionWithCounts[];
  title?: string;
  description?: string;
};

export function PopularRegions({
  regions,
  title = "Regions",
  description = "Pick a region to browse deals nearby.",
}: PopularRegionsProps) {
  if (regions.length === 0) {
    return (
      <p className="rounded-xl border border-dashed border-border px-4 py-8 text-center text-sm text-muted">
        No regions yet.
      </p>
    );
  }

  return (
    <div className="space-y-4">
      <div className="space-y-1">
        <h2 className="text-xl font-semibold text-foreground">{title}</h2>
        <p className="text-sm text-muted">{description}</p>
      </div>

      <ul className="grid gap-2 sm:grid-cols-2">
        {regions.map((region) => {
          const thumbUrl = regionHeroThumbUrl(region.heroImage);

          return (
            <li key={region.id}>
              <Link
                href={regionPath(region.name)}
                className="flex items-center justify-between gap-3 rounded-lg px-3 py-2.5 text-left transition-colors hover:bg-surface-muted"
              >
                <span className="flex min-w-0 items-center gap-3">
                  {thumbUrl ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={thumbUrl}
                      alt=""
                      className="h-14 w-14 shrink-0 rounded-lg object-cover"
                    />
                  ) : null}
                  <span className="font-medium text-foreground">
                    {region.name}
                  </span>
                </span>
                <span className="flex shrink-0 flex-col items-end text-sm leading-tight text-muted">
                  <span>
                    {region.venueCount}{" "}
                    {region.venueCount === 1 ? "venue" : "venues"}
                  </span>
                  <span>
                    {region.dealCount}{" "}
                    {region.dealCount === 1 ? "deal" : "deals"}
                  </span>
                </span>
              </Link>
            </li>
          );
        })}
      </ul>
    </div>
  );
}
