import { auth } from "@/lib/auth";
import {
  listFavoriteDealIds,
  setFavoriteDeal,
} from "@/lib/favorites/queries";
import { getDealsByIds } from "@/lib/search/queries";
import { NextResponse } from "next/server";

type FavoriteRequestBody = {
  dealId?: unknown;
  favorited?: unknown;
};

function parseDealId(value: unknown): number {
  if (typeof value === "number") {
    return value;
  }

  if (typeof value === "string") {
    return Number(value);
  }

  return NaN;
}

export async function GET(request: Request) {
  const session = await auth.api.getSession({ headers: request.headers });

  if (!session?.user.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  try {
    const dealIds = await listFavoriteDealIds(session.user.id);
    return NextResponse.json({ dealIds });
  } catch (error) {
    console.error("Failed to list favorites", error);
    return NextResponse.json(
      { error: "Failed to list favorites" },
      { status: 500 },
    );
  }
}

export async function POST(request: Request) {
  const session = await auth.api.getSession({ headers: request.headers });

  if (!session?.user.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  let body: FavoriteRequestBody;

  try {
    body = (await request.json()) as FavoriteRequestBody;
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const dealId = parseDealId(body.dealId);

  if (!Number.isFinite(dealId) || !Number.isInteger(dealId) || dealId <= 0) {
    return NextResponse.json({ error: "Invalid dealId" }, { status: 400 });
  }

  if (typeof body.favorited !== "boolean") {
    return NextResponse.json({ error: "Invalid favorited" }, { status: 400 });
  }

  if (body.favorited) {
    const deals = await getDealsByIds([dealId]);
    if (deals.length === 0) {
      return NextResponse.json({ error: "Deal not found" }, { status: 404 });
    }
  }

  try {
    const dealIds = await setFavoriteDeal(
      session.user.id,
      dealId,
      body.favorited,
    );
    return NextResponse.json({ ok: true, dealIds });
  } catch (error) {
    console.error("Failed to set favorite", error);
    return NextResponse.json(
      { error: "Failed to set favorite" },
      { status: 500 },
    );
  }
}
