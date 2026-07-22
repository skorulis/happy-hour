import Link from "next/link";
import { AdminDealActions } from "@/components/AdminDealActions";
import { AdminReportActions } from "@/components/AdminReportActions";
import { AdminTabs } from "@/components/AdminTabs";
import type { AdminPendingDeal } from "@/lib/deals/queries";
import type { AdminDealReport } from "@/lib/reports/queries";
import { getDealReportCategoryLabel } from "@/lib/reports/categories";
import type { AdminSyncRun } from "@/lib/sync/queries";
import { venuePath } from "@/lib/search/slugs";

type AdminPageContentProps = {
  pendingDeals: AdminPendingDeal[];
  reports: AdminDealReport[];
  syncRuns: AdminSyncRun[];
};

function formatSyncMode(mode: string): string {
  return mode === "all" ? "Full" : mode === "incremental" ? "Incremental" : mode;
}

function PendingDealsList({
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

function ReportsList({ reports }: { reports: AdminDealReport[] }) {
  if (reports.length === 0) {
    return (
      <p className="rounded-xl border border-dashed border-border px-4 py-8 text-center text-sm text-muted">
        No reports yet
      </p>
    );
  }

  return (
    <ul className="divide-y divide-border-subtle rounded-xl border border-border">
      {reports.map((report) => (
        <li
          key={report.id}
          className="flex items-start justify-between gap-4 px-4 py-4"
        >
          <div className="min-w-0 flex-1 space-y-2">
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
              <p className="text-sm text-secondary">{report.details}</p>
            ) : null}
            <p className="text-xs text-muted">
              {report.reporterEmail ?? "Anonymous"} ·{" "}
              {report.createdAt.toLocaleString()}
            </p>
          </div>
          <AdminReportActions reportId={report.id} />
        </li>
      ))}
    </ul>
  );
}

function RecentSyncsList({ syncRuns }: { syncRuns: AdminSyncRun[] }) {
  if (syncRuns.length === 0) {
    return (
      <p className="rounded-xl border border-dashed border-border px-4 py-8 text-center text-sm text-muted">
        No syncs yet
      </p>
    );
  }

  return (
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
  );
}

export function AdminPageContent({
  pendingDeals,
  reports,
  syncRuns,
}: AdminPageContentProps) {
  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-6 py-10">
      <header className="space-y-2">
        <h1 className="text-3xl font-bold text-foreground">Admin</h1>
      </header>

      <AdminTabs
        ariaLabel="Admin sections"
        defaultTabId="reports"
        tabs={[
          {
            id: "reports",
            label: "Reports",
            badgeCount: reports.length,
            content: <ReportsList reports={reports} />,
          },
          {
            id: "pending-deals",
            label: "Pending deals",
            badgeCount: pendingDeals.length,
            content: <PendingDealsList pendingDeals={pendingDeals} />,
          },
          {
            id: "recent-syncs",
            label: "Recent syncs",
            content: <RecentSyncsList syncRuns={syncRuns} />,
          },
        ]}
      />
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
