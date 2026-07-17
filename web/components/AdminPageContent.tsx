import Link from "next/link";
import type { AdminDealReport } from "@/lib/reports/queries";
import { getDealReportCategoryLabel } from "@/lib/reports/categories";
import type { AdminSyncRun } from "@/lib/sync/queries";
import { venuePath } from "@/lib/search/slugs";

type AdminPageContentProps = {
  reports: AdminDealReport[];
  syncRuns: AdminSyncRun[];
};

function formatSyncMode(mode: string): string {
  return mode === "all" ? "Full" : mode === "incremental" ? "Incremental" : mode;
}

export function AdminPageContent({
  reports,
  syncRuns,
}: AdminPageContentProps) {
  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-6 py-10">
      <header className="space-y-2">
        <h1 className="text-3xl font-bold text-foreground">
          Admin
        </h1>
      </header>

      <section className="space-y-4">
        <h2 className="text-xl font-semibold text-foreground">
          Reports
        </h2>

        {reports.length === 0 ? (
          <p className="rounded-xl border border-dashed border-border px-4 py-8 text-center text-sm text-muted">
            No reports yet
          </p>
        ) : (
          <ul className="divide-y divide-border-subtle rounded-xl border border-border">
            {reports.map((report) => (
              <li key={report.id} className="px-4 py-4">
                <div className="space-y-2">
                  <p className="text-sm font-medium text-foreground">
                    {getDealReportCategoryLabel(report.category)}
                  </p>
                  <p className="text-sm text-secondary">
                    {report.dealTitle ?? "Untitled deal"}
                  </p>
                  <p className="text-sm text-muted">
                    <Link
                      href={venuePath(report.venueSuburbName, report.venueName)}
                      className="text-accent-soft hover:underline"
                    >
                      {report.venueName}
                      {report.venueSuburbName
                        ? ` · ${report.venueSuburbName}`
                        : null}
                    </Link>
                  </p>
                  {report.details ? (
                    <p className="text-sm text-secondary">
                      {report.details}
                    </p>
                  ) : null}
                  <p className="text-xs text-muted">
                    {report.reporterEmail ?? "Anonymous"} ·{" "}
                    {report.createdAt.toLocaleString()}
                  </p>
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>

      <section className="space-y-4">
        <h2 className="text-xl font-semibold text-foreground">
          Recent syncs
        </h2>

        {syncRuns.length === 0 ? (
          <p className="rounded-xl border border-dashed border-border px-4 py-8 text-center text-sm text-muted">
            No syncs yet
          </p>
        ) : (
          <ul className="divide-y divide-border-subtle rounded-xl border border-border">
            {syncRuns.map((run) => (
              <li key={run.id} className="px-4 py-4">
                <div className="flex flex-wrap items-baseline justify-between gap-2">
                  <p className="text-sm font-medium text-foreground">
                    {formatSyncMode(run.mode)}
                    {run.finishedAt == null ? (
                      <span className="ml-2 text-xs font-normal text-accent-soft">
                        Incomplete
                      </span>
                    ) : null}
                  </p>
                  <p className="text-xs text-muted">
                    {run.startedAt.toLocaleString()}
                  </p>
                </div>
                <p className="mt-1 text-sm text-secondary">
                  {run.venuesSynced} venues · {run.dealsSynced} deals ·{" "}
                  {run.suburbsSynced} suburbs
                </p>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}

function RestrictedMessage() {
  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col px-6 py-10">
      <p className="text-sm text-secondary">
        This page is restricted to admin users
      </p>
    </div>
  );
}

export { RestrictedMessage };
