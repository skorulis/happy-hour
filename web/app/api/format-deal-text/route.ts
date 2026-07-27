import {
  formatDealText,
  validateFormatDealTextRequest,
} from "@/lib/extract/format-deal-text";
import { NextResponse } from "next/server";

export async function POST(request: Request) {
  let body: unknown;

  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const validated = validateFormatDealTextRequest(body);
  if (!validated.ok) {
    return NextResponse.json({ error: validated.error }, { status: 400 });
  }

  return NextResponse.json(formatDealText(validated.value));
}
