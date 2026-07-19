import Link from "next/link";
import type { PopularSuburb } from "@/lib/search/queries";
import { suburbWherePath } from "@/lib/search/slugs";
import { suburbHeroThumbUrl } from "@/lib/search/venue-hero-url";

type PopularSuburbsProps = {
  suburbs: PopularSuburb[];
  search?: string;
  title?: string;
  description?: string;
};

function formatSuburbLabel(suburb: PopularSuburb): string {
  return suburb.postcode ? `${suburb.name} (${suburb.postcode})` : suburb.name;
}

export function PopularSuburbs({
  suburbs,
  search,
  title = "Popular suburbs",
  description = "Pick a suburb to browse deals nearby.",
}: PopularSuburbsProps) {
  if (suburbs.length === 0) {
    return (
      <p className="rounded-xl border border-dashed border-border px-4 py-8 text-center text-sm text-muted">
        No suburbs with deals yet. Try Near me or search for a suburb above.
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
        {suburbs.map((suburb) => {
          const path = suburbWherePath(suburb.name, suburb.postcode);
          const href = search ? `${path}?${search}` : path;
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
                <span className="shrink-0 text-sm text-muted">
                  {suburb.dealCount}{" "}
                  {suburb.dealCount === 1 ? "deal" : "deals"}
                </span>
              </Link>
            </li>
          );
        })}
      </ul>
    </div>
  );
}
