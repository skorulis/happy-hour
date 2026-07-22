import type { Metadata } from "next";
import { PopularRegions } from "@/components/PopularRegions";
import { RegionsMapLoader } from "@/components/RegionsMapLoader";
import { listRegions } from "@/lib/search/queries";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "Regions",
  description: "Browse happy hour deals by geographic region.",
};

export default async function RegionsPage() {
  const regions = await listRegions();

  return (
    <div className="mx-auto flex w-full max-w-5xl flex-1 flex-col gap-8 px-4 py-10 md:px-6">
      <header>
        <h1 className="text-3xl font-bold text-foreground">Regions</h1>
        <p className="mt-2 text-sm text-muted">
          Browse pub and bar happy hour deals by area.
        </p>
      </header>

      <section aria-labelledby="regions-map-heading">
        <h2 id="regions-map-heading" className="sr-only">
          Region map
        </h2>
        <div role="img" aria-labelledby="regions-map-heading">
          <RegionsMapLoader regions={regions} />
        </div>
      </section>

      <section>
        <PopularRegions regions={regions} title="All regions" />
      </section>
    </div>
  );
}
