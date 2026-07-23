import { NextResponse } from "next/server";
import { searchSuburbs } from "@/lib/search/queries";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const query = searchParams.get("q") ?? "";
  const limit = Number(searchParams.get("limit") ?? "20");
  const regionIdParam = searchParams.get("regionId");
  const regionId =
    regionIdParam !== null && regionIdParam !== ""
      ? Number(regionIdParam)
      : undefined;
  const latParam = searchParams.get("lat");
  const lngParam = searchParams.get("lng");
  const lat =
    latParam !== null && latParam !== "" ? Number(latParam) : undefined;
  const lng =
    lngParam !== null && lngParam !== "" ? Number(lngParam) : undefined;

  if (
    regionId !== undefined &&
    (!Number.isFinite(regionId) || regionId < 1 || !Number.isInteger(regionId))
  ) {
    return NextResponse.json({ error: "Invalid regionId" }, { status: 400 });
  }

  if (lat !== undefined && !Number.isFinite(lat)) {
    return NextResponse.json({ error: "Invalid lat" }, { status: 400 });
  }

  if (lng !== undefined && !Number.isFinite(lng)) {
    return NextResponse.json({ error: "Invalid lng" }, { status: 400 });
  }

  if ((lat !== undefined) !== (lng !== undefined)) {
    return NextResponse.json(
      { error: "lat and lng must be provided together" },
      { status: 400 },
    );
  }

  if (lat !== undefined && (lat < -90 || lat > 90)) {
    return NextResponse.json({ error: "Invalid lat" }, { status: 400 });
  }

  if (lng !== undefined && (lng < -180 || lng > 180)) {
    return NextResponse.json({ error: "Invalid lng" }, { status: 400 });
  }

  try {
    const suburbs = await searchSuburbs(
      query,
      Number.isFinite(limit) ? limit : 20,
      { regionId, lat, lng },
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
