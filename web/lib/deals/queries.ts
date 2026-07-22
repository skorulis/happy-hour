import { user } from "@/db/auth-schema";
import {
  deal,
  dealSchedule,
  suburb,
  venue,
  type DealStatus,
} from "@/db/schema";
import { db } from "@/lib/db";
import { formatScheduleSummary } from "@/lib/search/schedule";
import { and, desc, eq, inArray } from "drizzle-orm";

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

export type UserDealContribution = {
  id: number;
  title: string | null;
  details: string | null;
  status: DealStatus;
  syncedAt: Date;
  venueName: string;
  venueSuburbName: string | null;
  scheduleSummary: string;
};

async function queryPendingDeals(
  venueId?: number,
): Promise<AdminPendingDeal[]> {
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
    .where(
      and(
        eq(deal.status, "new"),
        venueId != null ? eq(deal.venueId, venueId) : undefined,
      ),
    )
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

export async function getPendingDeals(): Promise<AdminPendingDeal[]> {
  return queryPendingDeals();
}

export async function getPendingDealsForVenue(
  venueId: number,
): Promise<AdminPendingDeal[]> {
  return queryPendingDeals(venueId);
}

export type EditableVenueDealSchedule = {
  dayOfWeek: number;
  startMinute: number;
  endMinute: number;
};

export type EditableVenueDeal = {
  id: number;
  title: string | null;
  details: string | null;
  conditions: string | null;
  startDate: string | null;
  endDate: string | null;
  status: Extract<DealStatus, "approved" | "rejected">;
  imageUrl: string | null;
  schedules: EditableVenueDealSchedule[];
};

export async function getEditableDealsForVenue(
  venueId: number,
): Promise<EditableVenueDeal[]> {
  const rows = await db
    .select({
      id: deal.id,
      title: deal.title,
      details: deal.details,
      conditions: deal.conditions,
      startDate: deal.startDate,
      endDate: deal.endDate,
      status: deal.status,
      imageUrl: deal.imageUrl,
    })
    .from(deal)
    .where(
      and(
        eq(deal.venueId, venueId),
        inArray(deal.status, ["approved", "rejected"]),
      ),
    )
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

  const schedulesByDeal = new Map<number, EditableVenueDealSchedule[]>();
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
    startDate: row.startDate,
    endDate: row.endDate,
    status: row.status as Extract<DealStatus, "approved" | "rejected">,
    imageUrl: row.imageUrl,
    schedules: schedulesByDeal.get(row.id) ?? [],
  }));
}

export async function getContributionsForUser(
  userId: string,
): Promise<UserDealContribution[]> {
  const rows = await db
    .select({
      id: deal.id,
      title: deal.title,
      details: deal.details,
      status: deal.status,
      syncedAt: deal.syncedAt,
      venueName: venue.name,
      venueSuburbName: suburb.name,
    })
    .from(deal)
    .innerJoin(venue, eq(deal.venueId, venue.id))
    .leftJoin(suburb, eq(venue.suburbId, suburb.id))
    .where(eq(deal.userId, userId))
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
    status: row.status as DealStatus,
    syncedAt: row.syncedAt,
    venueName: row.venueName,
    venueSuburbName: row.venueSuburbName,
    scheduleSummary: formatScheduleSummary(schedulesByDeal.get(row.id) ?? []),
  }));
}
