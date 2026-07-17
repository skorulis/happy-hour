import Link from "next/link";
import type { PopularSuburb } from "@/lib/search/queries";
import { suburbWherePath } from "@/lib/search/slugs";

type PopularSuburbsProps = {
  suburbs: PopularSuburb[];
  search?: string;
};

function formatSuburbLabel(suburb: PopularSuburb): string {
  return suburb.postcode ? `${suburb.name} (${suburb.postcode})` : suburb.name;
}

export function PopularSuburbs({ suburbs, search }: PopularSuburbsProps) {
  if (suburbs.length === 0) {
    return (
      <p className="rounded-xl border border-dashed border-zinc-300 px-4 py-8 text-center text-sm text-zinc-500 dark:border-zinc-700 dark:text-zinc-400">
        No suburbs with deals yet. Try Near me or search for a suburb above.
      </p>
    );
  }

  return (
    <div className="space-y-4">
      <div className="space-y-1">
        <h2 className="text-xl font-semibold text-zinc-900 dark:text-zinc-50">
          Popular suburbs
        </h2>
        <p className="text-sm text-zinc-500 dark:text-zinc-400">
          Pick a suburb to browse deals nearby.
        </p>
      </div>

      <ul className="grid gap-2 sm:grid-cols-2">
        {suburbs.map((suburb) => {
          const path = suburbWherePath(suburb.name, suburb.postcode);
          const href = search ? `${path}?${search}` : path;

          return (
            <li key={suburb.id}>
              <Link
                href={href}
                className="flex items-baseline justify-between gap-3 rounded-lg px-3 py-2.5 text-left transition-colors hover:bg-zinc-100 dark:hover:bg-zinc-800"
              >
                <span className="font-medium text-zinc-900 dark:text-zinc-50">
                  {formatSuburbLabel(suburb)}
                </span>
                <span className="shrink-0 text-sm text-zinc-500 dark:text-zinc-400">
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
