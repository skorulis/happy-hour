import { asc, count, isNotNull } from "drizzle-orm";
import { searchQueries } from "@/db/schema";
import { db } from "@/lib/db";

export type SearchDayCount = {
  day: number;
  count: number;
};

export async function getSearchesByDay(): Promise<SearchDayCount[]> {
  const rows = await db
    .select({
      day: searchQueries.day,
      count: count(searchQueries.id),
    })
    .from(searchQueries)
    .where(isNotNull(searchQueries.day))
    .groupBy(searchQueries.day)
    .orderBy(asc(searchQueries.day));

  return rows.flatMap((row) =>
    row.day !== null && row.day >= 1 && row.day <= 7
      ? [{ day: row.day, count: row.count }]
      : [],
  );
}
