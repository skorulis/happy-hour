import { user } from "@/db/auth-schema";
import { deal, dealSchedule, suburb, venue } from "@/db/schema";
import { db } from "@/lib/db";
import { formatScheduleSummary } from "@/lib/search/schedule";
import { desc, eq, inArray } from "drizzle-orm";

export type AdminPendingDeal = {
  id: number;
  title: string | null;
  details: string | null;
  conditions: string | null;
  imageUrl: string | null;
  syncedAt: Date;
  venueName: string;
  venueSuburbName: string | null;
  submitterEmail: string | null;
  scheduleSummary: string;
};

export async function getPendingDeals(): Promise<AdminPendingDeal[]> {
  const rows = await db
    .select({
      id: deal.id,
      title: deal.title,
      details: deal.details,
      conditions: deal.conditions,
      imageUrl: deal.imageUrl,
      syncedAt: deal.syncedAt,
      venueName: venue.name,
      venueSuburbName: suburb.name,
      submitterEmail: user.email,
    })
    .from(deal)
    .innerJoin(venue, eq(deal.venueId, venue.id))
    .leftJoin(suburb, eq(venue.suburbId, suburb.id))
    .leftJoin(user, eq(deal.userId, user.id))
    .where(eq(deal.status, "new"))
    .orderBy(desc(deal.syncedAt));

  if (rows.length === 0) {
    return [];
  }

  const dealIds = rows.map((row) => row.id);
  const schedules = await db
    .select({
      dealId: dealSchedule.dealId,
      dayOfWeek: dealSchedule.dayOfWeek,
      startMinute: dealSchedule.startMinute,
      endMinute: dealSchedule.endMinute,
    })
    .from(dealSchedule)
    .where(inArray(dealSchedule.dealId, dealIds))
    .orderBy(dealSchedule.dayOfWeek, dealSchedule.startMinute);

  const schedulesByDeal = new Map<
    number,
    { dayOfWeek: number; startMinute: number; endMinute: number }[]
  >();
  for (const schedule of schedules) {
    const existing = schedulesByDeal.get(schedule.dealId) ?? [];
    existing.push({
      dayOfWeek: schedule.dayOfWeek,
      startMinute: schedule.startMinute,
      endMinute: schedule.endMinute,
    });
    schedulesByDeal.set(schedule.dealId, existing);
  }

  return rows.map((row) => ({
    id: row.id,
    title: row.title,
    details: row.details,
    conditions: row.conditions,
    imageUrl: row.imageUrl,
    syncedAt: row.syncedAt,
    venueName: row.venueName,
    venueSuburbName: row.venueSuburbName,
    submitterEmail: row.submitterEmail,
    scheduleSummary: formatScheduleSummary(schedulesByDeal.get(row.id) ?? []),
  }));
}
