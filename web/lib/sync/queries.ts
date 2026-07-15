import { syncRun, type SyncRun } from "@/db/schema";
import { db } from "@/lib/db";
import { desc } from "drizzle-orm";

export type AdminSyncRun = SyncRun;

export async function getRecentSyncRuns(limit = 5): Promise<AdminSyncRun[]> {
  return db
    .select()
    .from(syncRun)
    .orderBy(desc(syncRun.startedAt))
    .limit(limit);
}
