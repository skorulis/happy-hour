import { user } from "@/db/auth-schema";
import {
  deal,
  dealReport,
  type DealReportCategory,
  type DealReportStatus,
  suburb,
  venue,
} from "@/db/schema";
import { db } from "@/lib/db";
import { and, desc, eq, inArray } from "drizzle-orm";

export type AdminDealReport = {
  id: number;
  category: DealReportCategory;
  details: string | null;
  createdAt: Date;
  dealId: number;
  dealTitle: string | null;
  venueName: string;
  venueSuburbName: string | null;
  reporterEmail: string | null;
};

export type UserDealReport = {
  id: number;
  category: DealReportCategory;
  details: string | null;
  status: DealReportStatus;
  createdAt: Date;
  dealId: number;
  dealTitle: string | null;
  venueName: string;
  venueSuburbName: string | null;
};

export async function getAllDealReports(): Promise<AdminDealReport[]> {
  const rows = await db
    .select({
      id: dealReport.id,
      category: dealReport.category,
      details: dealReport.details,
      createdAt: dealReport.createdAt,
      dealId: dealReport.dealId,
      dealTitle: deal.title,
      venueName: venue.name,
      venueSuburbName: suburb.name,
      reporterEmail: user.email,
    })
    .from(dealReport)
    .innerJoin(deal, eq(dealReport.dealId, deal.id))
    .innerJoin(venue, eq(deal.venueId, venue.id))
    .leftJoin(suburb, eq(venue.suburbId, suburb.id))
    .leftJoin(user, eq(dealReport.userId, user.id))
    .where(eq(dealReport.status, "new"))
    .orderBy(desc(dealReport.createdAt));

  return rows.map((row) => ({
    id: row.id,
    category: row.category as DealReportCategory,
    details: row.details,
    createdAt: row.createdAt,
    dealId: row.dealId,
    dealTitle: row.dealTitle,
    venueName: row.venueName,
    venueSuburbName: row.venueSuburbName,
    reporterEmail: row.reporterEmail,
  }));
}

export async function getReportsForUser(
  userId: string,
): Promise<UserDealReport[]> {
  const rows = await db
    .select({
      id: dealReport.id,
      category: dealReport.category,
      details: dealReport.details,
      status: dealReport.status,
      createdAt: dealReport.createdAt,
      dealId: dealReport.dealId,
      dealTitle: deal.title,
      venueName: venue.name,
      venueSuburbName: suburb.name,
    })
    .from(dealReport)
    .innerJoin(deal, eq(dealReport.dealId, deal.id))
    .innerJoin(venue, eq(deal.venueId, venue.id))
    .leftJoin(suburb, eq(venue.suburbId, suburb.id))
    .where(eq(dealReport.userId, userId))
    .orderBy(desc(dealReport.createdAt));

  return rows.map((row) => ({
    id: row.id,
    category: row.category as DealReportCategory,
    details: row.details,
    status: row.status as DealReportStatus,
    createdAt: row.createdAt,
    dealId: row.dealId,
    dealTitle: row.dealTitle,
    venueName: row.venueName,
    venueSuburbName: row.venueSuburbName,
  }));
}

/** Deal IDs that have at least one unresolved (status=new) report. */
export async function getDealIdsWithOpenReports(
  dealIds: number[],
): Promise<Set<number>> {
  if (dealIds.length === 0) {
    return new Set();
  }

  const rows = await db
    .selectDistinct({ dealId: dealReport.dealId })
    .from(dealReport)
    .where(
      and(inArray(dealReport.dealId, dealIds), eq(dealReport.status, "new")),
    );

  return new Set(rows.map((row) => row.dealId));
}
