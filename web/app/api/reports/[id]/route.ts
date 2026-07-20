import { deal, dealReport } from "@/db/schema";
import { isAdmin } from "@/lib/admin";
import { auth } from "@/lib/auth";
import { db } from "@/lib/db";
import { eq } from "drizzle-orm";
import { NextResponse } from "next/server";

type ReportActionBody = {
  action?: unknown;
};

type RouteContext = {
  params: Promise<{ id: string }>;
};

function parseReportId(value: string): number {
  const id = Number(value);
  return Number.isFinite(id) && Number.isInteger(id) && id > 0 ? id : NaN;
}

export async function PATCH(request: Request, context: RouteContext) {
  const session = await auth.api.getSession({ headers: request.headers });

  if (!session?.user.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  if (!isAdmin(session.user.email)) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const { id: idParam } = await context.params;
  const reportId = parseReportId(idParam);

  if (!Number.isFinite(reportId)) {
    return NextResponse.json({ error: "Invalid report id" }, { status: 400 });
  }

  let body: ReportActionBody;

  try {
    body = (await request.json()) as ReportActionBody;
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  if (body.action !== "approve" && body.action !== "reject") {
    return NextResponse.json({ error: "Invalid action" }, { status: 400 });
  }

  const [existing] = await db
    .select({
      id: dealReport.id,
      dealId: dealReport.dealId,
      status: dealReport.status,
    })
    .from(dealReport)
    .where(eq(dealReport.id, reportId))
    .limit(1);

  if (!existing) {
    return NextResponse.json({ error: "Report not found" }, { status: 404 });
  }

  if (existing.status !== "new") {
    return NextResponse.json(
      { error: "Report has already been resolved" },
      { status: 409 },
    );
  }

  try {
    if (body.action === "approve") {
      await db.transaction(async (tx) => {
        await tx
          .update(dealReport)
          .set({ status: "approved" })
          .where(eq(dealReport.id, reportId));

        await tx
          .update(deal)
          .set({ status: "rejected" })
          .where(eq(deal.id, existing.dealId));
      });
    } else {
      await db
        .update(dealReport)
        .set({ status: "rejected" })
        .where(eq(dealReport.id, reportId));
    }

    return NextResponse.json({ ok: true });
  } catch (error) {
    console.error("Failed to update deal report", error);
    return NextResponse.json(
      { error: "Failed to update report" },
      { status: 500 },
    );
  }
}
