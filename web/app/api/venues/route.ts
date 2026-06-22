import { NextResponse } from "next/server";
import { searchVenues } from "@/lib/search/queries";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const query = searchParams.get("q") ?? "";
  const limit = Number(searchParams.get("limit") ?? "20");

  try {
    const venues = await searchVenues(query, Number.isFinite(limit) ? limit : 20);
    return NextResponse.json({ venues });
  } catch (error) {
    console.error("Failed to search venues", error);
    return NextResponse.json(
      { error: "Failed to search venues" },
      { status: 500 },
    );
  }
}
