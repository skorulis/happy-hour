import { NextResponse } from "next/server";
import { listPopularSuburbs } from "@/lib/search/queries";

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
  const daysParam = searchParams.get("days");
  const startMinuteParam = searchParams.get("startMinute");
  const endMinuteParam = searchParams.get("endMinute");
  const query = searchParams.get("q") ?? undefined;
  const limit = Number(searchParams.get("limit") ?? "20");

  const days = parseDaysParam(daysParam);
  const startMinute =
    startMinuteParam !== null && startMinuteParam !== ""
      ? Number(startMinuteParam)
      : undefined;
  const endMinute =
    endMinuteParam !== null && endMinuteParam !== ""
      ? Number(endMinuteParam)
      : undefined;

  if (days === "invalid") {
    return NextResponse.json({ error: "Invalid days" }, { status: 400 });
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
    const suburbs = await listPopularSuburbs(
      Number.isFinite(limit) ? limit : 20,
      {
        days,
        startMinute,
        endMinute,
        query,
      },
    );
    return NextResponse.json({ suburbs });
  } catch (error) {
    console.error("Failed to list popular suburbs", error);
    return NextResponse.json(
      { error: "Failed to list popular suburbs" },
      { status: 500 },
    );
  }
}
