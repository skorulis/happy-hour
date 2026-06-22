import { NextResponse } from "next/server";
import { getVenueDetail } from "@/lib/search/queries";

type RouteContext = {
  params: Promise<{ id: string }>;
};

export async function GET(_request: Request, context: RouteContext) {
  const { id } = await context.params;
  const venueId = Number(id);

  if (!Number.isFinite(venueId)) {
    return NextResponse.json({ error: "Invalid venue id" }, { status: 400 });
  }

  try {
    const venue = await getVenueDetail(venueId);

    if (!venue) {
      return NextResponse.json({ error: "Venue not found" }, { status: 404 });
    }

    return NextResponse.json({ venue });
  } catch (error) {
    console.error("Failed to load venue", error);
    return NextResponse.json({ error: "Failed to load venue" }, { status: 500 });
  }
}
