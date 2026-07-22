import { user } from "@/db/auth-schema";
import { suburb, venue, venueOwnership } from "@/db/schema";
import { db } from "@/lib/db";
import { and, asc, eq, sql } from "drizzle-orm";

export type VenueOwner = {
  userId: string;
  email: string;
  name: string;
  createdAt: Date;
};

export async function isVenueOwner(
  userId: string,
  venueId: number,
): Promise<boolean> {
  const [row] = await db
    .select({ venueId: venueOwnership.venueId })
    .from(venueOwnership)
    .where(
      and(
        eq(venueOwnership.userId, userId),
        eq(venueOwnership.venueId, venueId),
      ),
    )
    .limit(1);

  return row !== undefined;
}

export async function listVenueOwners(venueId: number): Promise<VenueOwner[]> {
  return db
    .select({
      userId: venueOwnership.userId,
      email: user.email,
      name: user.name,
      createdAt: venueOwnership.createdAt,
    })
    .from(venueOwnership)
    .innerJoin(user, eq(venueOwnership.userId, user.id))
    .where(eq(venueOwnership.venueId, venueId))
    .orderBy(asc(venueOwnership.createdAt));
}

export async function findUserByEmail(
  email: string,
): Promise<{ id: string; email: string; name: string } | null> {
  const normalized = email.trim().toLowerCase();
  if (!normalized) {
    return null;
  }

  const [row] = await db
    .select({ id: user.id, email: user.email, name: user.name })
    .from(user)
    .where(sql`lower(${user.email}) = ${normalized}`)
    .limit(1);

  return row ?? null;
}

export async function addVenueOwner(
  userId: string,
  venueId: number,
): Promise<boolean> {
  const inserted = await db
    .insert(venueOwnership)
    .values({ userId, venueId })
    .onConflictDoNothing({
      target: [venueOwnership.userId, venueOwnership.venueId],
    })
    .returning({ userId: venueOwnership.userId });

  return inserted.length > 0;
}

export async function removeVenueOwner(
  userId: string,
  venueId: number,
): Promise<boolean> {
  const deleted = await db
    .delete(venueOwnership)
    .where(
      and(
        eq(venueOwnership.userId, userId),
        eq(venueOwnership.venueId, venueId),
      ),
    )
    .returning({ userId: venueOwnership.userId });

  return deleted.length > 0;
}

export async function getVenueForOwnership(
  venueId: number,
): Promise<{ id: number; name: string; suburbName: string | null } | null> {
  const [row] = await db
    .select({
      id: venue.id,
      name: venue.name,
      suburbName: suburb.name,
    })
    .from(venue)
    .leftJoin(suburb, eq(venue.suburbId, suburb.id))
    .where(eq(venue.id, venueId))
    .limit(1);

  return row ?? null;
}

export type OwnedVenue = {
  id: number;
  name: string;
  suburbName: string | null;
};

export async function listVenuesForOwner(
  userId: string,
): Promise<OwnedVenue[]> {
  return db
    .select({
      id: venue.id,
      name: venue.name,
      suburbName: suburb.name,
    })
    .from(venueOwnership)
    .innerJoin(venue, eq(venueOwnership.venueId, venue.id))
    .leftJoin(suburb, eq(venue.suburbId, suburb.id))
    .where(eq(venueOwnership.userId, userId))
    .orderBy(asc(venue.name));
}

export async function userOwnsAnyVenue(userId: string): Promise<boolean> {
  const [row] = await db
    .select({ venueId: venueOwnership.venueId })
    .from(venueOwnership)
    .where(eq(venueOwnership.userId, userId))
    .limit(1);

  return row !== undefined;
}
