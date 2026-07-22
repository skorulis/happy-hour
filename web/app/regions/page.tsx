import type { Metadata } from "next";
import { PopularRegions } from "@/components/PopularRegions";
import { listRegions } from "@/lib/search/queries";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "Regions",
  description: "Browse happy hour deals by geographic region.",
};

export default async function RegionsPage() {
  const regions = await listRegions();

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-6 py-10">
      <header>
        <h1 className="text-3xl font-bold text-foreground">Regions</h1>
        <p className="mt-2 text-sm text-muted">
          Browse pub and bar happy hour deals by area.
        </p>
      </header>

      <section>
        <PopularRegions regions={regions} />
      </section>
    </div>
  );
}
