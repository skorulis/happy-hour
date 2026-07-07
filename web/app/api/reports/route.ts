import { dealReport } from "@/db/schema";
import { auth } from "@/lib/auth";
import { db } from "@/lib/db";
import { isDealReportCategory } from "@/lib/reports/categories";
import { getDealsByIds } from "@/lib/search/queries";
import { NextResponse } from "next/server";

const MAX_DETAILS_LENGTH = 2000;

type ReportRequestBody = {
  dealId?: unknown;
  category?: unknown;
  details?: unknown;
};

export async function POST(request: Request) {
  let body: ReportRequestBody;

  try {
    body = (await request.json()) as ReportRequestBody;
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const dealId =
    typeof body.dealId === "number"
      ? body.dealId
      : typeof body.dealId === "string"
        ? Number(body.dealId)
        : NaN;

  if (!Number.isFinite(dealId) || !Number.isInteger(dealId) || dealId <= 0) {
    return NextResponse.json({ error: "Invalid dealId" }, { status: 400 });
  }

  if (typeof body.category !== "string" || !isDealReportCategory(body.category)) {
    return NextResponse.json({ error: "Invalid category" }, { status: 400 });
  }

  let details: string | null = null;
  if (body.details !== undefined && body.details !== null) {
    if (typeof body.details !== "string") {
      return NextResponse.json({ error: "Invalid details" }, { status: 400 });
    }

    const trimmedDetails = body.details.trim();
    if (trimmedDetails.length > MAX_DETAILS_LENGTH) {
      return NextResponse.json(
        { error: `Details must be at most ${MAX_DETAILS_LENGTH} characters` },
        { status: 400 },
      );
    }

    details = trimmedDetails.length > 0 ? trimmedDetails : null;
  }

  const deals = await getDealsByIds([dealId]);
  if (deals.length === 0) {
    return NextResponse.json({ error: "Deal not found" }, { status: 404 });
  }

  const session = await auth.api.getSession({ headers: request.headers });

  try {
    await db.insert(dealReport).values({
      dealId,
      userId: session?.user.id ?? null,
      category: body.category,
      details,
    });

    return NextResponse.json({ ok: true }, { status: 201 });
  } catch (error) {
    console.error("Failed to create deal report", error);
    return NextResponse.json(
      { error: "Failed to submit report" },
      { status: 500 },
    );
  }
}
