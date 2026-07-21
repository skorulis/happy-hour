import { deal } from "@/db/schema";
import { isAdmin } from "@/lib/admin";
import { auth } from "@/lib/auth";
import { db } from "@/lib/db";
import { eq } from "drizzle-orm";
import { NextResponse } from "next/server";

type DealActionBody = {
  action?: unknown;
};

type RouteContext = {
  params: Promise<{ id: string }>;
};

function parseDealId(value: string): number {
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
  const dealId = parseDealId(idParam);

  if (!Number.isFinite(dealId)) {
    return NextResponse.json({ error: "Invalid deal id" }, { status: 400 });
  }

  let body: DealActionBody;

  try {
    body = (await request.json()) as DealActionBody;
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  if (body.action !== "approve" && body.action !== "reject") {
    return NextResponse.json({ error: "Invalid action" }, { status: 400 });
  }

  const [existing] = await db
    .select({
      id: deal.id,
      status: deal.status,
    })
    .from(deal)
    .where(eq(deal.id, dealId))
    .limit(1);

  if (!existing) {
    return NextResponse.json({ error: "Deal not found" }, { status: 404 });
  }

  if (existing.status !== "new") {
    return NextResponse.json(
      { error: "Deal has already been resolved" },
      { status: 409 },
    );
  }

  try {
    await db
      .update(deal)
      .set({
        status: body.action === "approve" ? "approved" : "rejected",
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
