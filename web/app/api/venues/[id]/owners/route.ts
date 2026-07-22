import { canManageVenue } from "@/lib/admin";
import { auth } from "@/lib/auth";
import { sendVenueAdminAddedEmail } from "@/lib/email";
import { venuePath } from "@/lib/search/slugs";
import {
  addVenueOwner,
  findUserByEmail,
  getVenueForOwnership,
  isVenueOwner,
  removeVenueOwner,
} from "@/lib/venue-ownership/queries";
import { NextResponse } from "next/server";

type RouteContext = {
  params: Promise<{ id: string }>;
};

type AddOwnerBody = {
  email?: unknown;
};

type RemoveOwnerBody = {
  userId?: unknown;
};

function parseVenueId(value: string): number {
  const id = Number(value);
  return Number.isFinite(id) && Number.isInteger(id) && id > 0 ? id : NaN;
}

function appOrigin(): string {
  return process.env.BETTER_AUTH_URL?.trim() || "http://localhost:3000";
}

async function requireVenueManager(request: Request, venueIdParam: string) {
  const session = await auth.api.getSession({ headers: request.headers });

  if (!session?.user.id) {
    return {
      error: NextResponse.json({ error: "Unauthorized" }, { status: 401 }),
    };
  }

  const venueId = parseVenueId(venueIdParam);
  if (!Number.isFinite(venueId)) {
    return {
      error: NextResponse.json({ error: "Invalid venue id" }, { status: 400 }),
    };
  }

  const venue = await getVenueForOwnership(venueId);
  if (!venue) {
    return {
      error: NextResponse.json({ error: "Venue not found" }, { status: 404 }),
    };
  }

  if (!(await canManageVenue(session.user, venueId))) {
    return {
      error: NextResponse.json({ error: "Forbidden" }, { status: 403 }),
    };
  }

  return { session, venueId, venue };
}

export async function POST(request: Request, context: RouteContext) {
  const { id: idParam } = await context.params;
  const gated = await requireVenueManager(request, idParam);
  if ("error" in gated) {
    return gated.error;
  }

  const { venueId, venue } = gated;

  let body: AddOwnerBody;
  try {
    body = (await request.json()) as AddOwnerBody;
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  if (typeof body.email !== "string" || !body.email.trim()) {
    return NextResponse.json({ error: "Invalid email" }, { status: 400 });
  }

  const foundUser = await findUserByEmail(body.email);
  if (!foundUser) {
    return NextResponse.json(
      { error: "No account found for that email" },
      { status: 404 },
    );
  }

  if (await isVenueOwner(foundUser.id, venueId)) {
    return NextResponse.json(
      { error: "User is already an admin for this venue" },
      { status: 409 },
    );
  }

  try {
    const added = await addVenueOwner(foundUser.id, venueId);
    if (!added) {
      return NextResponse.json(
        { error: "User is already an admin for this venue" },
        { status: 409 },
      );
    }

    const adminUrl = `${appOrigin()}${venuePath(venue.suburbName, venue.name)}/admin`;
    await sendVenueAdminAddedEmail({
      to: foundUser.email,
      venueName: venue.name,
      adminUrl,
    });

    return NextResponse.json({ ok: true });
  } catch (error) {
    console.error("Failed to add venue owner", error);
    return NextResponse.json(
      { error: "Failed to add venue admin" },
      { status: 500 },
    );
  }
}

export async function DELETE(request: Request, context: RouteContext) {
  const { id: idParam } = await context.params;
  const gated = await requireVenueManager(request, idParam);
  if ("error" in gated) {
    return gated.error;
  }

  const { session, venueId } = gated;

  let body: RemoveOwnerBody;
  try {
    body = (await request.json()) as RemoveOwnerBody;
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  if (typeof body.userId !== "string" || !body.userId.trim()) {
    return NextResponse.json({ error: "Invalid userId" }, { status: 400 });
  }

  const userId = body.userId.trim();

  if (userId === session.user.id) {
    return NextResponse.json(
      { error: "You cannot remove yourself" },
      { status: 400 },
    );
  }

  try {
    const removed = await removeVenueOwner(userId, venueId);
    if (!removed) {
      return NextResponse.json(
        { error: "Venue admin not found" },
        { status: 404 },
      );
    }

    return NextResponse.json({ ok: true });
  } catch (error) {
    console.error("Failed to remove venue owner", error);
    return NextResponse.json(
      { error: "Failed to remove venue admin" },
      { status: 500 },
    );
  }
}
