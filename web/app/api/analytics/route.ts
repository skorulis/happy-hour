import { sendAnalyticsEvent } from "@/lib/analytics/send";
import { validateAnalyticsTrackRequest } from "@/lib/analytics/validate";
import { auth } from "@/lib/auth";
import { NextResponse } from "next/server";

export async function POST(request: Request) {
  let body: unknown;

  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const validated = validateAnalyticsTrackRequest(body);
  if (!validated.ok) {
    return NextResponse.json({ error: validated.error }, { status: 400 });
  }

  const session = await auth.api.getSession({ headers: request.headers });

  try {
    await sendAnalyticsEvent({
      ...validated.value,
      user_id: session?.user.id ?? null,
    });

    return NextResponse.json({ ok: true });
  } catch (error) {
    console.error("Failed to send analytics event", error);
    return NextResponse.json(
      { error: "Failed to track event" },
      { status: 500 },
    );
  }
}
