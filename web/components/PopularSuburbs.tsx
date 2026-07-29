import Link from "next/link";
import { List, LocateFixed } from "lucide-react";
import type { PopularSuburb, SuburbStatistics } from "@/lib/search/queries";
import {
  NEARBY_WHERE_SLUG,
  suburbWherePath,
} from "@/lib/search/slugs";
import { suburbHeroThumbUrl } from "@/lib/search/venue-hero-url";
import { appendFiltersToPath } from "@/lib/search/what-path";

type PopularSuburbsProps = {
  suburbs: PopularSuburb[] | SuburbStatistics[];
  search?: string;
  days?: number[];
  what?: string[];
  title?: string;
  description?: string;
  hideHeader?: boolean;
  hideStats?: boolean;
  includeSpecialLinks?: boolean;
  includeNearbyLink?: boolean;
  allSuburbsHref?: string;
  statsMode?: "counts" | "perSqkm" | "perThousand";
  /** Override suburb list links (default: suburb deal browse path). */
  suburbHref?: (suburb: PopularSuburb) => string;
};

type SuburbListItem =
  | { kind: "suburb"; suburb: PopularSuburb }
  | {
      kind: "special";
      id: "nearby" | "all-suburbs";
      label: string;
      href: string;
    };

function formatSuburbLabel(suburb: PopularSuburb): string {
  return suburb.postcode ? `${suburb.name} (${suburb.postcode})` : suburb.name;
}

function formatPerSqkm(value: number | null): string {
  return value === null ? "—" : value.toFixed(1);
}

function formatPerThousand(value: number | null): string {
  return value === null ? "—" : value.toFixed(1);
}

function isSuburbStatistics(suburb: PopularSuburb): suburb is SuburbStatistics {
  return (
    "venuesPerSqkm" in suburb &&
    "dealsPerSqkm" in suburb &&
    "venuesPerThousand" in suburb &&
    "dealsPerThousand" in suburb
  );
}

function hrefWithSearch(path: string, search: string | undefined): string {
  return search ? `${path}?${search}` : path;
}

function buildListItems(
  suburbs: PopularSuburb[],
  search: string | undefined,
  days: number[],
  what: string[],
  includeSpecialLinks: boolean,
  includeNearbyLink: boolean,
  allSuburbsHref: string,
): SuburbListItem[] {
  const items: SuburbListItem[] = suburbs.map((suburb) => ({
    kind: "suburb",
    suburb,
  }));

  if (!includeSpecialLinks) {
    return items;
  }

  const nearbyPath = appendFiltersToPath(`/${NEARBY_WHERE_SLUG}`, days, what);
  const nearbyHref = hrefWithSearch(nearbyPath, search);

  const result: SuburbListItem[] = [];

  if (includeNearbyLink) {
    result.push({
      kind: "special",
      id: "nearby",
      label: "Nearby",
      href: nearbyHref,
    });
  }

  result.push(...items);

  result.push({
    kind: "special",
    id: "all-suburbs",
    label: "All suburbs",
    href: allSuburbsHref,
  });

  return result;
}

export function PopularSuburbs({
  suburbs,
  search,
  days = [],
  what = [],
  title = "Popular suburbs",
  description = "Pick a suburb to browse deals nearby.",
  hideHeader = false,
  hideStats = false,
  includeSpecialLinks = false,
  includeNearbyLink = true,
  allSuburbsHref = "/all-suburbs",
  statsMode = "counts",
  suburbHref,
}: PopularSuburbsProps) {
  const items = buildListItems(
    suburbs,
    search,
    days,
    what,
    includeSpecialLinks,
    includeNearbyLink,
    allSuburbsHref,
  );

  if (items.length === 0) {
    return (
      <p className="rounded-xl border border-dashed border-border px-4 py-8 text-center text-sm text-muted">
        No suburbs with deals yet. Try Near me or search for a suburb above.
      </p>
    );
  }

  return (
    <div className="space-y-4">
      {!hideHeader && (
        <div className="space-y-1">
          <h2 className="text-xl font-semibold text-foreground">{title}</h2>
          <p className="text-sm text-muted">{description}</p>
        </div>
      )}

      <ul className="grid gap-2 sm:grid-cols-2">
        {items.map((item) => {
          if (item.kind === "special") {
            return (
              <li key={item.id}>
                <Link
                  href={item.href}
                  className="flex items-center justify-between gap-3 rounded-lg px-3 py-2.5 text-left transition-colors hover:bg-surface-muted"
                >
                  <span className="flex min-w-0 items-center gap-3">
                    <span className="inline-flex h-14 w-14 shrink-0 items-center justify-center rounded-lg bg-accent-muted text-accent-soft">
                      {item.id === "nearby" ? (
                        <LocateFixed
                          aria-hidden
                          className="h-5 w-5"
                          strokeWidth={1.75}
                        />
                      ) : (
                        <List
                          aria-hidden
                          className="h-5 w-5"
                          strokeWidth={1.75}
                        />
                      )}
                    </span>
                    <span className="font-medium text-foreground">
                      {item.label}
                    </span>
                  </span>
                </Link>
              </li>
            );
          }

          const { suburb } = item;
          const path = suburbHref
            ? suburbHref(suburb)
            : appendFiltersToPath(
                suburbWherePath(suburb.name, suburb.postcode),
                days,
                what,
              );
          const href = suburbHref ? path : hrefWithSearch(path, search);
          const thumbUrl = suburbHeroThumbUrl(suburb.heroImage);

          return (
            <li key={suburb.id}>
              <Link
                href={href}
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
                    {formatSuburbLabel(suburb)}
                  </span>
                </span>
                {!hideStats && <span className="flex shrink-0 flex-col items-end text-sm leading-tight text-muted">
                  {statsMode === "perSqkm" && isSuburbStatistics(suburb) ? (
                    <>
                      <span>
                        {formatPerSqkm(suburb.venuesPerSqkm)} venues/km²
                      </span>
                      <span>
                        {formatPerSqkm(suburb.dealsPerSqkm)} deals/km²
                      </span>
                    </>
                  ) : statsMode === "perThousand" &&
                    isSuburbStatistics(suburb) ? (
                    <>
                      <span>
                        {formatPerThousand(suburb.venuesPerThousand)} venues/1k
                      </span>
                      <span>
                        {formatPerThousand(suburb.dealsPerThousand)} deals/1k
                      </span>
                    </>
                  ) : (
                    <>
                      <span>
                        {suburb.venueCount}{" "}
                        {suburb.venueCount === 1 ? "venue" : "venues"}
                      </span>
                      <span>
                        {suburb.dealCount}{" "}
                        {suburb.dealCount === 1 ? "deal" : "deals"}
                      </span>
                    </>
                  )}
                </span>}
              </Link>
            </li>
          );
        })}
      </ul>
    </div>
  );
}
