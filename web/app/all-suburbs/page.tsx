import type { Metadata } from "next";
import { PopularSuburbs } from "@/components/PopularSuburbs";
import { listAllSuburbs } from "@/lib/search/queries";

// Needs Postgres at request time — skip static prerender during Docker builds.
export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "All suburbs",
  description: "Browse every suburb, ordered by deal count.",
};

export default async function AllSuburbsPage() {
  const suburbs = await listAllSuburbs();

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-6 py-10">
      <header>
        <h1 className="text-3xl font-bold text-foreground">All suburbs</h1>
      </header>

      <section>
        <PopularSuburbs
          suburbs={suburbs}
          title="All suburbs"
          description="Browse every suburb."
        />
      </section>
    </div>
  );
}
