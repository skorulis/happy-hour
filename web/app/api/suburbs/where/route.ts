import { NextResponse } from "next/server";
import { findSuburbByWhereSlug } from "@/lib/search/queries";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const slug = searchParams.get("slug");

  if (slug === null || slug.trim() === "") {
    return NextResponse.json({ error: "slug is required" }, { status: 400 });
  }

  const suburb = await findSuburbByWhereSlug(slug.trim());
  if (!suburb) {
    return NextResponse.json({ error: "Suburb not found" }, { status: 404 });
  }

  return NextResponse.json({ suburb });
}
