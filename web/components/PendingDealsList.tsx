import Link from "next/link";
import { AdminDealActions } from "@/components/AdminDealActions";
import type { AdminPendingDeal } from "@/lib/deals/queries";
import { venuePath } from "@/lib/search/slugs";

export function PendingDealsList({
  pendingDeals,
}: {
  pendingDeals: AdminPendingDeal[];
}) {
  if (pendingDeals.length === 0) {
    return (
      <p className="rounded-xl border border-dashed border-border px-4 py-8 text-center text-sm text-muted">
        No pending deals
      </p>
    );
  }

  return (
    <ul className="divide-y divide-border-subtle rounded-xl border border-border">
      {pendingDeals.map((pendingDeal) => (
        <li
          key={pendingDeal.id}
          className="flex items-start justify-between gap-4 px-4 py-4"
        >
          <div className="flex min-w-0 flex-1 gap-3">
            {pendingDeal.imageUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={pendingDeal.imageUrl}
                alt=""
                className="h-16 w-16 shrink-0 rounded-lg object-cover"
              />
            ) : null}
            <div className="min-w-0 flex-1 space-y-2">
              <p className="text-sm font-medium text-foreground">
                {pendingDeal.title ?? "Untitled deal"}
              </p>
              {pendingDeal.details ? (
                <p className="text-sm text-secondary">{pendingDeal.details}</p>
              ) : null}
              {pendingDeal.conditions ? (
                <p className="text-sm text-secondary">
                  {pendingDeal.conditions}
                </p>
              ) : null}
              <p className="text-sm text-muted">{pendingDeal.scheduleSummary}</p>
              <p className="text-sm text-muted">
                <Link
                  href={venuePath(
                    pendingDeal.venueSuburbName,
                    pendingDeal.venueName,
                  )}
                  className="text-accent-soft hover:underline"
                >
                  {pendingDeal.venueName}
                  {pendingDeal.venueSuburbName
                    ? ` · ${pendingDeal.venueSuburbName}`
                    : null}
                </Link>
              </p>
              <p className="text-xs text-muted">
                {pendingDeal.submitterEmail ?? "Anonymous"} ·{" "}
                {pendingDeal.syncedAt.toLocaleString()}
              </p>
            </div>
          </div>
          <AdminDealActions dealId={pendingDeal.id} />
        </li>
      ))}
    </ul>
  );
}
