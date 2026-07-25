import { searchQueries, type SearchQueryType } from "@/db/schema";
import type {
  AnalyticsEventProperties,
  AnalyticsEventType,
} from "@/lib/analytics/types";
import { db } from "@/lib/db";

export type SearchQueryInsert = {
  userId: string | null;
  type: SearchQueryType;
  suburbId: number | null;
  day: number | null;
  products: string | null;
};

function parseDay(daysValue: unknown): number | null {
  if (typeof daysValue !== "string" || daysValue.length === 0) {
    return null;
  }

  const parts = daysValue
    .split(",")
    .map((part) => part.trim())
    .filter((part) => part.length > 0);

  if (parts.length !== 1) {
    return null;
  }

  const day = Number(parts[0]);
  if (!Number.isInteger(day) || day < 1 || day > 7) {
    return null;
  }

  return day;
}

function parseSuburbId(value: unknown): number | null {
  if (typeof value !== "number" || !Number.isInteger(value) || value <= 0) {
    return null;
  }
  return value;
}

function parseProducts(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

/**
 * Convert a validated `search_performed` event into a `search_queries` row.
 * Returns null for unsupported where kinds (e.g. anywhere) or non-search events.
 */
export function searchQueryFromEvent(input: {
  event_type: AnalyticsEventType;
  user_id?: string | null;
  event_properties?: AnalyticsEventProperties;
}): SearchQueryInsert | null {
  if (input.event_type !== "search_performed") {
    return null;
  }

  const properties = input.event_properties ?? {};
  const whereKind = properties.where_kind;

  let type: SearchQueryType;
  if (whereKind === "nearMe") {
    type = "nearby";
  } else if (whereKind === "suburb") {
    type = "suburb";
  } else {
    return null;
  }

  return {
    userId: input.user_id ?? null,
    type,
    suburbId: type === "suburb" ? parseSuburbId(properties.suburb_id) : null,
    day: parseDay(properties.days),
    products: parseProducts(properties.what),
  };
}

export async function insertSearchQuery(
  row: SearchQueryInsert,
): Promise<void> {
  await db.insert(searchQueries).values(row);
}

export async function recordSearchQueryFromEvent(input: {
  event_type: AnalyticsEventType;
  user_id?: string | null;
  event_properties?: AnalyticsEventProperties;
}): Promise<{ recorded: boolean }> {
  const row = searchQueryFromEvent(input);
  if (!row) {
    return { recorded: false };
  }

  await insertSearchQuery(row);
  return { recorded: true };
}
