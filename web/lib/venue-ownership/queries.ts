import { and, eq } from "drizzle-orm";
import { venueOwnership } from "@/db/schema";
import { db } from "@/lib/db";

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
