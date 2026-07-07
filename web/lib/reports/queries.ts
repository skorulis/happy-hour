import { user } from "@/db/auth-schema";
import {
  deal,
  dealReport,
  type DealReportCategory,
  suburb,
  venue,
} from "@/db/schema";
import { db } from "@/lib/db";
import { desc, eq } from "drizzle-orm";

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
