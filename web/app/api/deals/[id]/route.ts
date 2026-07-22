import { deal } from "@/db/schema";
import { canManageVenue, isAdmin } from "@/lib/admin";
import { auth } from "@/lib/auth";
import {
  CreateUserDealsValidationError,
  parseUserDealInput,
} from "@/lib/deals/create-user-deals";
import { updateManagedDeal } from "@/lib/deals/update-deal";
import { db } from "@/lib/db";
import { eq } from "drizzle-orm";
import { NextResponse } from "next/server";

type RouteContext = {
  params: Promise<{ id: string }>;
};

function parseDealId(value: string): number {
  const id = Number(value);
  return Number.isFinite(id) && Number.isInteger(id) && id > 0 ? id : NaN;
}

async function patchDealAction(
  dealId: number,
  action: "approve" | "reject",
  existing: { status: string; venueId: number },
  user: { id: string; email: string },
) {
  if (existing.status !== "new") {
    return NextResponse.json(
      { error: "Deal has already been resolved" },
      { status: 409 },
    );
  }

  const admin = isAdmin(user.email);
  const venueManager = await canManageVenue(user, existing.venueId);

  if (!admin && !venueManager) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  try {
    await db
      .update(deal)
      .set({
        status: action === "approve" ? "approved" : "rejected",
      })
      .where(eq(deal.id, dealId));

    return NextResponse.json({ ok: true });
  } catch (error) {
    console.error("Failed to update deal", error);
    return NextResponse.json(
      { error: "Failed to update deal" },
      { status: 500 },
    );
  }
}

async function patchDealFields(
  dealId: number,
  body: Record<string, unknown>,
  existing: { status: string; venueId: number },
  user: { id: string; email: string },
) {
  if (existing.status !== "approved" && existing.status !== "rejected") {
    return NextResponse.json(
      { error: "Pending deals must be approved or rejected first" },
      { status: 409 },
    );
  }

  const admin = isAdmin(user.email);
  const venueManager = await canManageVenue(user, existing.venueId);

  if (!admin && !venueManager) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  if (body.status !== "approved" && body.status !== "rejected") {
    return NextResponse.json({ error: "Invalid status" }, { status: 400 });
  }

  try {
    const parsed = parseUserDealInput(body);
    await updateManagedDeal(dealId, {
      ...parsed,
      status: body.status,
    });
    return NextResponse.json({ ok: true });
  } catch (error) {
    if (error instanceof CreateUserDealsValidationError) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }
    console.error("Failed to update deal", error);
    return NextResponse.json(
      { error: "Failed to update deal" },
      { status: 500 },
    );
  }
}

export async function PATCH(request: Request, context: RouteContext) {
  const session = await auth.api.getSession({ headers: request.headers });

  if (!session?.user.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { id: idParam } = await context.params;
  const dealId = parseDealId(idParam);

  if (!Number.isFinite(dealId)) {
    return NextResponse.json({ error: "Invalid deal id" }, { status: 400 });
  }

  let body: Record<string, unknown>;

  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const [existing] = await db
    .select({
      id: deal.id,
      status: deal.status,
      venueId: deal.venueId,
    })
    .from(deal)
    .where(eq(deal.id, dealId))
    .limit(1);

  if (!existing) {
    return NextResponse.json({ error: "Deal not found" }, { status: 404 });
  }

  if (body.action === "approve" || body.action === "reject") {
    return patchDealAction(dealId, body.action, existing, session.user);
  }

  if ("schedules" in body || "status" in body) {
    return patchDealFields(dealId, body, existing, session.user);
  }

  return NextResponse.json({ error: "Invalid request body" }, { status: 400 });
}
