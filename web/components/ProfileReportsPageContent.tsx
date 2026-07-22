import Link from "next/link";
import { CancelReportButton } from "@/components/CancelReportButton";
import { getDealReportCategoryLabel } from "@/lib/reports/categories";
import type { UserDealReport } from "@/lib/reports/queries";
import { venuePath } from "@/lib/search/slugs";

type ProfileReportsPageContentProps = {
  openReports: UserDealReport[];
  historicalReports: UserDealReport[];
};

function formatResult(status: UserDealReport["status"]): string {
  if (status === "approved") {
    return "Approved";
  }
  if (status === "rejected") {
    return "Rejected";
  }
  return status;
}

function ReportDetails({ report }: { report: UserDealReport }) {
  return (
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
          {report.venueSuburbName ? ` · ${report.venueSuburbName}` : null}
        </Link>
      </p>
      {report.details ? (
        <p className="text-sm text-secondary">{report.details}</p>
      ) : null}
      <p className="text-xs text-muted">{report.createdAt.toLocaleString()}</p>
    </div>
  );
}

export function ProfileReportsPageContent({
  openReports,
  historicalReports,
}: ProfileReportsPageContentProps) {
  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-4 py-10 md:px-6">
      <header className="space-y-2">
        <h1 className="text-3xl font-bold text-foreground">Your reports</h1>
      </header>

      <section className="space-y-4">
        <h2 className="text-xl font-semibold text-foreground">Open reports</h2>

        {openReports.length === 0 ? (
          <p className="rounded-xl border border-dashed border-border px-4 py-8 text-center text-sm text-muted">
            No open reports
          </p>
        ) : (
          <ul className="divide-y divide-border-subtle rounded-xl border border-border">
            {openReports.map((report) => (
              <li
                key={report.id}
                className="flex items-start justify-between gap-4 px-4 py-4"
              >
                <ReportDetails report={report} />
                <CancelReportButton reportId={report.id} />
              </li>
            ))}
          </ul>
        )}
      </section>

      <section className="space-y-4">
        <h2 className="text-xl font-semibold text-foreground">
          Historical reports
        </h2>

        {historicalReports.length === 0 ? (
          <p className="rounded-xl border border-dashed border-border px-4 py-8 text-center text-sm text-muted">
            No historical reports
          </p>
        ) : (
          <ul className="divide-y divide-border-subtle rounded-xl border border-border">
            {historicalReports.map((report) => (
              <li
                key={report.id}
                className="flex items-start justify-between gap-4 px-4 py-4"
              >
                <ReportDetails report={report} />
                <p className="shrink-0 text-sm font-medium text-secondary">
                  {formatResult(report.status)}
                </p>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
