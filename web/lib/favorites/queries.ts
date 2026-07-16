import { and, eq } from "drizzle-orm";
import { favoriteDeal } from "@/db/schema";
import { db } from "@/lib/db";

export async function listFavoriteDealIds(userId: string): Promise<number[]> {
  const rows = await db
    .select({ dealId: favoriteDeal.dealId })
    .from(favoriteDeal)
    .where(eq(favoriteDeal.userId, userId));

  return rows.map((row) => row.dealId);
}

export async function setFavoriteDeal(
  userId: string,
  dealId: number,
  favorited: boolean,
): Promise<number[]> {
  if (favorited) {
    await db
      .insert(favoriteDeal)
      .values({ userId, dealId })
      .onConflictDoNothing({
        target: [favoriteDeal.userId, favoriteDeal.dealId],
      });
  } else {
    await db
      .delete(favoriteDeal)
      .where(
        and(eq(favoriteDeal.userId, userId), eq(favoriteDeal.dealId, dealId)),
      );
  }

  return listFavoriteDealIds(userId);
}
