import {
  and,
  eq,
  exists,
  ilike,
  inArray,
  or,
  sql,
  type SQL,
} from "drizzle-orm";
import { db } from "@/lib/db";
import {
  currentCalendarWeekday,
  currentMinuteOfDay,
} from "@/lib/search/schedule";
import { deal, dealSchedule, venue, venueLinks } from "@/db/schema";

export type VenueSearchResult = {
  id: number;
  name: string;
  lat: number;
  lng: number;
  websiteUri: string | null;
};

export type DealSearchResult = {
  id: number;
  title: string | null;
  details: string | null;
  conditions: string | null;
  imageUrl: string | null;
  sourceUrl: string | null;
  venue: {
    id: number;
    name: string;
    lat: number;
    lng: number;
    websiteUri: string | null;
  };
  schedules: Array<{
    dayOfWeek: number;
    startMinute: number;
    endMinute: number;
  }>;
};

export type VenueDetailResult = VenueSearchResult & {
  links: {
    whatsOn: string | null;
    instagram: string | null;
    facebook: string | null;
  } | null;
  deals: DealSearchResult[];
};

function activeNowScheduleFilter(now = new Date()): SQL {
  const day = currentCalendarWeekday(now);
  const minute = currentMinuteOfDay(now);

  return exists(
    db
      .select({ one: sql`1` })
      .from(dealSchedule)
      .where(
        and(
          eq(dealSchedule.dealId, deal.id),
          eq(dealSchedule.dayOfWeek, day),
          sql`${dealSchedule.startMinute} <= ${minute}`,
          sql`${dealSchedule.endMinute} > ${minute}`,
        ),
      ),
  );
}

function dayScheduleFilter(day: number): SQL {
  return exists(
    db
      .select({ one: sql`1` })
      .from(dealSchedule)
      .where(
        and(
          eq(dealSchedule.dealId, deal.id),
          eq(dealSchedule.dayOfWeek, day),
        ),
      ),
  );
}

function textSearchFilter(query: string): SQL {
  return sql`${dealSearchVector} @@ plainto_tsquery('english', ${query})`;
}

const dealSearchVector = sql`to_tsvector('english', coalesce(${deal.title}, '') || ' ' || coalesce(${deal.details}, '') || ' ' || coalesce(${deal.conditions}, ''))`;

export async function searchVenues(
  query: string,
  limit = 20,
): Promise<VenueSearchResult[]> {
  const trimmed = query.trim();

  if (!trimmed) {
    return db
      .select({
        id: venue.id,
        name: venue.name,
        lat: venue.lat,
        lng: venue.lng,
        websiteUri: venue.websiteUri,
      })
      .from(venue)
      .orderBy(venue.name)
      .limit(limit);
  }

  return db
    .select({
      id: venue.id,
      name: venue.name,
      lat: venue.lat,
      lng: venue.lng,
      websiteUri: venue.websiteUri,
    })
    .from(venue)
    .where(
      or(
        ilike(venue.name, `%${trimmed}%`),
        sql`similarity(${venue.name}, ${trimmed}) > 0.2`,
      ),
    )
    .orderBy(sql`similarity(${venue.name}, ${trimmed}) DESC`, venue.name)
    .limit(limit);
}

export async function searchDeals(options: {
  venueId?: number;
  day?: number;
  query?: string;
  activeNow?: boolean;
  limit?: number;
}): Promise<DealSearchResult[]> {
  const filters: SQL[] = [];

  if (options.venueId !== undefined) {
    filters.push(eq(deal.venueId, options.venueId));
  }

  if (options.day !== undefined) {
    filters.push(dayScheduleFilter(options.day));
  }

  if (options.activeNow) {
    filters.push(activeNowScheduleFilter());
  }

  const trimmedQuery = options.query?.trim();
  if (trimmedQuery) {
    filters.push(textSearchFilter(trimmedQuery));
  }

  const rows = await db
    .select({
      dealId: deal.id,
      title: deal.title,
      details: deal.details,
      conditions: deal.conditions,
      imageUrl: deal.imageUrl,
      sourceUrl: deal.sourceUrl,
      venueId: venue.id,
      venueName: venue.name,
      venueLat: venue.lat,
      venueLng: venue.lng,
      venueWebsiteUri: venue.websiteUri,
    })
    .from(deal)
    .innerJoin(venue, eq(deal.venueId, venue.id))
    .where(filters.length > 0 ? and(...filters) : undefined)
    .orderBy(venue.name, deal.title)
    .limit(options.limit ?? 100);

  if (rows.length === 0) {
    return [];
  }

  const dealIds = rows.map((row) => row.dealId);
  const schedules = await db
    .select()
    .from(dealSchedule)
    .where(inArray(dealSchedule.dealId, dealIds))
    .orderBy(dealSchedule.dayOfWeek, dealSchedule.startMinute);

  const schedulesByDeal = new Map<number, DealSearchResult["schedules"]>();
  for (const schedule of schedules) {
    const existing = schedulesByDeal.get(schedule.dealId) ?? [];
    existing.push({
      dayOfWeek: schedule.dayOfWeek,
      startMinute: schedule.startMinute,
      endMinute: schedule.endMinute,
    });
    schedulesByDeal.set(schedule.dealId, existing);
  }

  return rows.map((row) => ({
    id: row.dealId,
    title: row.title,
    details: row.details,
    conditions: row.conditions,
    imageUrl: row.imageUrl,
    sourceUrl: row.sourceUrl,
    venue: {
      id: row.venueId,
      name: row.venueName,
      lat: row.venueLat,
      lng: row.venueLng,
      websiteUri: row.venueWebsiteUri,
    },
    schedules: schedulesByDeal.get(row.dealId) ?? [],
  }));
}

export async function getVenueDetail(
  venueId: number,
): Promise<VenueDetailResult | null> {
  const [venueRow] = await db
    .select()
    .from(venue)
    .where(eq(venue.id, venueId))
    .limit(1);

  if (!venueRow) {
    return null;
  }

  const [linksRow] = await db
    .select()
    .from(venueLinks)
    .where(eq(venueLinks.venueId, venueId))
    .limit(1);

  const deals = await searchDeals({ venueId, limit: 500 });

  return {
    id: venueRow.id,
    name: venueRow.name,
    lat: venueRow.lat,
    lng: venueRow.lng,
    websiteUri: venueRow.websiteUri,
    links: linksRow
      ? {
          whatsOn: linksRow.whatsOn,
          instagram: linksRow.instagram,
          facebook: linksRow.facebook,
        }
      : null,
    deals,
  };
}
