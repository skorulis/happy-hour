import { NextResponse } from "next/server";
import { searchSuburbs } from "@/lib/search/queries";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const query = searchParams.get("q") ?? "";
  const limit = Number(searchParams.get("limit") ?? "20");

  try {
    const suburbs = await searchSuburbs(
      query,
      Number.isFinite(limit) ? limit : 20,
    );

    return NextResponse.json({ suburbs });
  } catch (error) {
    console.error("Failed to search suburbs", error);
    return NextResponse.json(
      { error: "Failed to search suburbs" },
      { status: 500 },
    );
  }
}
