import { NextResponse } from "next/server";
import { searchDeals, searchDealsForSuburb } from "@/lib/search/queries";

function parseDaysParam(value: string | null): number[] | undefined | "invalid" {
  if (value === null || value.trim() === "") {
    return undefined;
  }

  const days = value
    .split(",")
    .map((part) => Number(part.trim()))
    .filter((day) => Number.isFinite(day));

  if (days.length === 0) {
    return undefined;
  }

  for (const day of days) {
    if (day < 1 || day > 7) {
      return "invalid";
    }
  }

  return days;
}

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const venueIdParam = searchParams.get("venueId");
  const dayParam = searchParams.get("day");
  const daysParam = searchParams.get("days");
  const suburbIdParam = searchParams.get("suburbId");
  const latParam = searchParams.get("lat");
  const lngParam = searchParams.get("lng");
  const startMinuteParam = searchParams.get("startMinute");
  const endMinuteParam = searchParams.get("endMinute");
  const query = searchParams.get("q") ?? undefined;
  const activeNow = searchParams.get("activeNow") === "true";
  const limit = Number(searchParams.get("limit") ?? "100");

  const venueId =
    venueIdParam !== null && venueIdParam !== ""
      ? Number(venueIdParam)
      : undefined;
  const day =
    dayParam !== null && dayParam !== "" ? Number(dayParam) : undefined;
  const days = parseDaysParam(daysParam);
  const suburbId =
    suburbIdParam !== null && suburbIdParam !== ""
      ? Number(suburbIdParam)
      : undefined;
  const lat =
    latParam !== null && latParam !== "" ? Number(latParam) : undefined;
  const lng =
    lngParam !== null && lngParam !== "" ? Number(lngParam) : undefined;
  const startMinute =
    startMinuteParam !== null && startMinuteParam !== ""
      ? Number(startMinuteParam)
      : undefined;
  const endMinute =
    endMinuteParam !== null && endMinuteParam !== ""
      ? Number(endMinuteParam)
      : undefined;

  if (venueId !== undefined && !Number.isFinite(venueId)) {
    return NextResponse.json({ error: "Invalid venueId" }, { status: 400 });
  }

  if (day !== undefined && (day < 1 || day > 7)) {
    return NextResponse.json({ error: "Invalid day" }, { status: 400 });
  }

  if (days === "invalid") {
    return NextResponse.json({ error: "Invalid days" }, { status: 400 });
  }

  if (suburbId !== undefined && !Number.isFinite(suburbId)) {
    return NextResponse.json({ error: "Invalid suburbId" }, { status: 400 });
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

  if (
    startMinute !== undefined &&
    (!Number.isFinite(startMinute) || startMinute < 0 || startMinute > 1439)
  ) {
    return NextResponse.json({ error: "Invalid startMinute" }, { status: 400 });
  }

  if (
    endMinute !== undefined &&
    (!Number.isFinite(endMinute) || endMinute < 1 || endMinute > 1440)
  ) {
    return NextResponse.json({ error: "Invalid endMinute" }, { status: 400 });
  }

  try {
    if (suburbId !== undefined) {
      const { deals, nearbyDeals } = await searchDealsForSuburb({
        venueId,
        day,
        days,
        suburbId,
        startMinute,
        endMinute,
        query,
        activeNow,
        limit: Number.isFinite(limit) ? limit : 100,
      });

      return NextResponse.json({ deals, nearbyDeals });
    }

    const deals = await searchDeals({
      venueId,
      day,
      days,
      startMinute,
      endMinute,
      query,
      activeNow,
      limit: Number.isFinite(limit) ? limit : 100,
      lat,
      lng,
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
