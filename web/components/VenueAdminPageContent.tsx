import Link from "next/link";
import { AdminReportActions } from "@/components/AdminReportActions";
import { AdminTabs } from "@/components/AdminTabs";
import { EditDealsList } from "@/components/EditDealsList";
import { PendingDealsList } from "@/components/PendingDealsList";
import { VenueAdminAccounts } from "@/components/VenueAdminAccounts";
import type {
  AdminPendingDeal,
  EditableVenueDeal,
} from "@/lib/deals/queries";
import type { AdminDealReport } from "@/lib/reports/queries";
import { getDealReportCategoryLabel } from "@/lib/reports/categories";
import { venuePath } from "@/lib/search/slugs";
import type { VenueOwner } from "@/lib/venue-ownership/queries";

type VenueAdminPageContentProps = {
  venueName: string;
  venueSuburbName: string | null;
  venueId: number;
  reports: AdminDealReport[];
  pendingDeals: AdminPendingDeal[];
  editableDeals: EditableVenueDeal[];
  owners: VenueOwner[];
  currentUserId: string;
};

function ReportsList({ reports }: { reports: AdminDealReport[] }) {
  if (reports.length === 0) {
    return (
      <p className="rounded-xl border border-dashed border-border px-4 py-8 text-center text-sm text-muted">
        No outstanding reports
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

export function VenueAdminPageContent({
  venueName,
  venueSuburbName,
  venueId,
  reports,
  pendingDeals,
  editableDeals,
  owners,
  currentUserId,
}: VenueAdminPageContentProps) {
  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-4 py-10 md:px-6">
      <header className="space-y-2">
        <Link
          href={venuePath(venueSuburbName, venueName)}
          className="text-sm font-medium text-accent-soft hover:text-foreground"
        >
          ← Back to venue
        </Link>
        <h1 className="text-3xl font-bold text-foreground">
          Admin · {venueName}
        </h1>
      </header>

      <AdminTabs
        ariaLabel="Venue admin sections"
        defaultTabId="reports"
        tabs={[
          {
            id: "reports",
            label: "Issue Reports",
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
            id: "edit-deals",
            label: "Edit deals",
            content: <EditDealsList deals={editableDeals} />,
          },
          {
            id: "accounts",
            label: "Accounts",
            content: (
              <VenueAdminAccounts
                venueId={venueId}
                owners={owners}
                currentUserId={currentUserId}
              />
            ),
          },
        ]}
      />
    </div>
  );
}
