import { asc, count, eq } from "drizzle-orm";
import { searchQueries } from "@/db/schema";
import { db } from "@/lib/db";

/** `null` day means no single day was selected (any day / multi-day). */
export type SearchDayCount = {
  day: number | null;
  count: number;
};

export type AnalyticsFilters = {
  suburbId?: number;
};

export async function getSearchesByDay(
  filters: AnalyticsFilters = {},
): Promise<SearchDayCount[]> {
  const rows = await db
    .select({
      day: searchQueries.day,
      count: count(searchQueries.id),
    })
    .from(searchQueries)
    .where(
      filters.suburbId === undefined
        ? undefined
        : eq(searchQueries.suburbId, filters.suburbId),
    )
    .groupBy(searchQueries.day)
    .orderBy(asc(searchQueries.day));

const results: SearchDayCount[] = [];
  for (const row of rows) {
    if (row.day === null) {
      results.push({ day: null, count: row.count });
    } else if (row.day >= 1 && row.day <= 7) {
      results.push({ day: row.day, count: row.count });
    }
  }
  return results;
}
