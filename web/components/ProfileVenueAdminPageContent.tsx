import Link from "next/link";
import type { OwnedVenue } from "@/lib/venue-ownership/queries";
import { venuePath } from "@/lib/search/slugs";

type ProfileVenueAdminPageContentProps = {
  venues: OwnedVenue[];
};

export function ProfileVenueAdminPageContent({
  venues,
}: ProfileVenueAdminPageContentProps) {
  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-6 py-10">
      <header className="space-y-2">
        <h1 className="text-3xl font-bold text-foreground">Venue admin</h1>
        <p className="text-sm text-secondary">
          Venues you can manage as an admin.
        </p>
      </header>

      {venues.length === 0 ? (
        <p className="rounded-xl border border-dashed border-border px-4 py-8 text-center text-sm text-muted">
          You are not an admin for any venues
        </p>
      ) : (
        <ul className="divide-y divide-border-subtle rounded-xl border border-border">
          {venues.map((ownedVenue) => {
            const path = venuePath(ownedVenue.suburbName, ownedVenue.name);
            return (
              <li key={ownedVenue.id} className="px-4 py-4">
                <Link
                  href={`${path}/admin`}
                  className="text-sm font-medium text-accent-soft hover:underline"
                >
                  {ownedVenue.name}
                  {ownedVenue.suburbName
                    ? ` · ${ownedVenue.suburbName}`
                    : null}
                </Link>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
