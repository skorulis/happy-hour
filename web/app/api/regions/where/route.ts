import { NextResponse } from "next/server";
import { findRegionBySlug } from "@/lib/search/queries";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const slug = searchParams.get("slug");

  if (slug === null || slug.trim() === "") {
    return NextResponse.json({ error: "slug is required" }, { status: 400 });
  }

  const region = await findRegionBySlug(slug.trim());
  if (!region) {
    return NextResponse.json({ error: "Region not found" }, { status: 404 });
  }

  return NextResponse.json({ region });
}
