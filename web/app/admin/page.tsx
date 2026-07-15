import type { Metadata } from "next";
import { headers } from "next/headers";
import {
  AdminPageContent,
  RestrictedMessage,
} from "@/components/AdminPageContent";
import { isAdmin } from "@/lib/admin";
import { auth } from "@/lib/auth";
import { getAllDealReports } from "@/lib/reports/queries";
import { getRecentSyncRuns } from "@/lib/sync/queries";

export const metadata: Metadata = {
  title: "Admin",
  description: "Happy Hours admin dashboard.",
};

export default async function AdminPage() {
  const session = await auth.api.getSession({
    headers: await headers(),
  });

  if (!session || !isAdmin(session.user.email)) {
    return <RestrictedMessage />;
  }

  const [reports, syncRuns] = await Promise.all([
    getAllDealReports(),
    getRecentSyncRuns(5),
  ]);

  return <AdminPageContent reports={reports} syncRuns={syncRuns} />;
}
