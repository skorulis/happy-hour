import { NextResponse } from "next/server";
import { searchDeals } from "@/lib/search/queries";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const venueIdParam = searchParams.get("venueId");
  const dayParam = searchParams.get("day");
  const query = searchParams.get("q") ?? undefined;
  const activeNow = searchParams.get("activeNow") === "true";
  const limit = Number(searchParams.get("limit") ?? "100");

  const venueId =
    venueIdParam !== null && venueIdParam !== ""
      ? Number(venueIdParam)
      : undefined;
  const day =
    dayParam !== null && dayParam !== "" ? Number(dayParam) : undefined;

  if (venueId !== undefined && !Number.isFinite(venueId)) {
    return NextResponse.json({ error: "Invalid venueId" }, { status: 400 });
  }

  if (day !== undefined && (day < 1 || day > 7)) {
    return NextResponse.json({ error: "Invalid day" }, { status: 400 });
  }

  try {
    const deals = await searchDeals({
      venueId,
      day,
      query,
      activeNow,
      limit: Number.isFinite(limit) ? limit : 100,
    });

    return NextResponse.json({ deals });
  } catch (error) {
    console.error("Failed to search deals", error);
    return NextResponse.json(
      { error: "Failed to search deals" },
      { status: 500 },
    );
  }
}
