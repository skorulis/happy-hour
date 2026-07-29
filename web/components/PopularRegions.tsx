import Link from "next/link";
import { LocateFixed, Search } from "lucide-react";
import type { RegionWithCounts } from "@/lib/search/queries";
import { NEARBY_WHERE_SLUG, regionPath } from "@/lib/search/slugs";
import { regionHeroThumbUrl } from "@/lib/search/venue-hero-url";

type PopularRegionsProps = {
  regions: RegionWithCounts[];
  title?: string;
  description?: string;
  includeNearbyLink?: boolean;
};

type CountryGroup = {
  countryName: string;
  countryIso3: string;
  regions: RegionWithCounts[];
  dealCount: number;
};

function groupRegionsByCountry(regions: RegionWithCounts[]): CountryGroup[] {
  const groups = new Map<string, CountryGroup>();

  for (const region of regions) {
    const existing = groups.get(region.countryIso3);
    if (existing) {
      existing.regions.push(region);
      existing.dealCount += region.dealCount;
      continue;
    }

    groups.set(region.countryIso3, {
      countryName: region.countryName,
      countryIso3: region.countryIso3,
      regions: [region],
      dealCount: region.dealCount,
    });
  }

  return [...groups.values()].sort((a, b) => {
    if (b.dealCount !== a.dealCount) {
      return b.dealCount - a.dealCount;
    }
    return a.countryName.localeCompare(b.countryName);
  });
}

function RegionLink({ region }: { region: RegionWithCounts }) {
  const thumbUrl = regionHeroThumbUrl(region.heroImage);

  return (
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
        <span className="font-medium text-foreground">{region.name}</span>
      </span>
      <span className="flex shrink-0 flex-col items-end text-sm leading-tight text-muted">
        <span>
          {region.venueCount}{" "}
          {region.venueCount === 1 ? "venue" : "venues"}
        </span>
        <span>
          {region.dealCount} {region.dealCount === 1 ? "deal" : "deals"}
        </span>
      </span>
    </Link>
  );
}

export function PopularRegions({
  regions,
  title = "Regions",
  description = "Pick a region to browse deals nearby.",
  includeNearbyLink = true,
}: PopularRegionsProps) {
  if (regions.length === 0 && !includeNearbyLink) {
    return (
      <p className="rounded-xl border border-dashed border-border px-4 py-8 text-center text-sm text-muted">
        No regions yet.
      </p>
    );
  }

  const nearbyHref = `/${NEARBY_WHERE_SLUG}`;
  const countryGroups = groupRegionsByCountry(regions);

  return (
    <div className="space-y-6">
      <div className="space-y-1">
        <h2 className="text-xl font-semibold text-foreground">{title}</h2>
        <p className="text-sm text-muted">{description}</p>
      </div>

      <ul className="grid gap-2 sm:grid-cols-2">
        {includeNearbyLink ? (
          <li>
            <Link
              href={nearbyHref}
              className="flex items-center justify-between gap-3 rounded-lg px-3 py-2.5 text-left transition-colors hover:bg-surface-muted"
            >
              <span className="flex min-w-0 items-center gap-3">
                <span className="inline-flex h-14 w-14 shrink-0 items-center justify-center rounded-lg bg-accent-muted text-accent-soft">
                  <LocateFixed
                    aria-hidden
                    className="h-5 w-5"
                    strokeWidth={1.75}
                  />
                </span>
                <span className="font-medium text-foreground">Nearby</span>
              </span>
            </Link>
          </li>
        ) : null}
        <li>
          <Link
            href="/venue-search"
            className="flex items-center justify-between gap-3 rounded-lg px-3 py-2.5 text-left transition-colors hover:bg-surface-muted"
          >
            <span className="flex min-w-0 items-center gap-3">
              <span className="inline-flex h-14 w-14 shrink-0 items-center justify-center rounded-lg bg-accent-muted text-accent-soft">
                <Search aria-hidden className="h-5 w-5" strokeWidth={1.75} />
              </span>
              <span className="font-medium text-foreground">
                Search by venue name
              </span>
            </span>
          </Link>
        </li>
      </ul>

      {countryGroups.map((group) => (
        <div key={group.countryIso3} className="space-y-3">
          <h3 className="text-sm font-medium tracking-[0.08em] text-muted uppercase">
            {group.countryName}
          </h3>
          <ul className="grid gap-2 sm:grid-cols-2">
            {group.regions.map((region) => (
              <li key={region.id}>
                <RegionLink region={region} />
              </li>
            ))}
          </ul>
        </div>
      ))}
    </div>
  );
}
