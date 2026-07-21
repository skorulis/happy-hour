import type { Metadata } from "next";
import { headers } from "next/headers";
import {
  AdminPageContent,
  RestrictedMessage,
} from "@/components/AdminPageContent";
import { isAdmin } from "@/lib/admin";
import { auth } from "@/lib/auth";
import { getPendingDeals } from "@/lib/deals/queries";
import { getAllDealReports } from "@/lib/reports/queries";
import { getRecentSyncRuns } from "@/lib/sync/queries";

export const metadata: Metadata = {
  title: "Admin",
  description: "DuskRoute admin dashboard.",
};

export default async function AdminPage() {
  const session = await auth.api.getSession({
    headers: await headers(),
  });

  if (!session || !isAdmin(session.user.email)) {
    return <RestrictedMessage />;
  }

  const [pendingDeals, reports, syncRuns] = await Promise.all([
    getPendingDeals(),
    getAllDealReports(),
    getRecentSyncRuns(5),
  ]);

  return (
    <AdminPageContent
      pendingDeals={pendingDeals}
      reports={reports}
      syncRuns={syncRuns}
    />
  );
}
