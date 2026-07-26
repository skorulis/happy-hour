import { asc, count } from "drizzle-orm";
import { searchQueries } from "@/db/schema";
import { db } from "@/lib/db";

/** `null` day means no single day was selected (any day / multi-day). */
export type SearchDayCount = {
  day: number | null;
  count: number;
};

export async function getSearchesByDay(): Promise<SearchDayCount[]> {
  const rows = await db
    .select({
      day: searchQueries.day,
      count: count(searchQueries.id),
    })
    .from(searchQueries)
    .groupBy(searchQueries.day)
    .orderBy(asc(searchQueries.day));

  return rows.flatMap((row) => {
    if (row.day === null) {
      return [{ day: null, count: row.count }];
    }
    if (row.day >= 1 && row.day <= 7) {
      return [{ day: row.day, count: row.count }];
    }
    return [];
  });
}
