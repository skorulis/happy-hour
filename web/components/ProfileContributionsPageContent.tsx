import Link from "next/link";
import type { UserDealContribution } from "@/lib/deals/queries";
import { venuePath } from "@/lib/search/slugs";

type ProfileContributionsPageContentProps = {
  pendingContributions: UserDealContribution[];
  historicalContributions: UserDealContribution[];
};

function formatResult(status: UserDealContribution["status"]): string {
  if (status === "approved") {
    return "Approved";
  }
  if (status === "rejected") {
    return "Rejected";
  }
  return status;
}

function ContributionDetails({
  contribution,
}: {
  contribution: UserDealContribution;
}) {
  return (
    <div className="min-w-0 flex-1 space-y-2">
      <p className="text-sm font-medium text-foreground">
        {contribution.title ?? "Untitled deal"}
      </p>
      {contribution.details ? (
        <p className="text-sm text-secondary">{contribution.details}</p>
      ) : null}
      {contribution.scheduleSummary ? (
        <p className="text-sm text-muted">{contribution.scheduleSummary}</p>
      ) : null}
      <p className="text-sm text-muted">
        <Link
          href={venuePath(contribution.venueSuburbName, contribution.venueName)}
          className="text-accent-soft hover:underline"
        >
          {contribution.venueName}
          {contribution.venueSuburbName
            ? ` · ${contribution.venueSuburbName}`
            : null}
        </Link>
      </p>
      <p className="text-xs text-muted">
        {contribution.syncedAt.toLocaleString()}
      </p>
    </div>
  );
}

export function ProfileContributionsPageContent({
  pendingContributions,
  historicalContributions,
}: ProfileContributionsPageContentProps) {
  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-6 py-10">
      <header className="space-y-2">
        <h1 className="text-3xl font-bold text-foreground">
          Your contributions
        </h1>
      </header>

      <section className="space-y-4">
        <h2 className="text-xl font-semibold text-foreground">
          Pending contributions
        </h2>

        {pendingContributions.length === 0 ? (
          <p className="rounded-xl border border-dashed border-border px-4 py-8 text-center text-sm text-muted">
            No pending contributions
          </p>
        ) : (
          <ul className="divide-y divide-border-subtle rounded-xl border border-border">
            {pendingContributions.map((contribution) => (
              <li key={contribution.id} className="px-4 py-4">
                <ContributionDetails contribution={contribution} />
              </li>
            ))}
          </ul>
        )}
      </section>

      <section className="space-y-4">
        <h2 className="text-xl font-semibold text-foreground">
          Historical contributions
        </h2>

        {historicalContributions.length === 0 ? (
          <p className="rounded-xl border border-dashed border-border px-4 py-8 text-center text-sm text-muted">
            No historical contributions
          </p>
        ) : (
          <ul className="divide-y divide-border-subtle rounded-xl border border-border">
            {historicalContributions.map((contribution) => (
              <li
                key={contribution.id}
                className="flex items-start justify-between gap-4 px-4 py-4"
              >
                <ContributionDetails contribution={contribution} />
                <p className="shrink-0 text-sm font-medium text-secondary">
                  {formatResult(contribution.status)}
                </p>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
