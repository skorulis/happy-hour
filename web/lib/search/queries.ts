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
import { deal, dealSchedule, suburb, venue, venueLinks } from "@/db/schema";

export type SuburbSearchResult = {
  id: number;
  name: string;
  postcode: string | null;
};

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
    heroImage: string | null;
    formattedAddress: string | null;
  };
  schedules: Array<{
    dayOfWeek: number;
    startMinute: number;
    endMinute: number;
  }>;
};

function parseVenueFormattedAddress(json: unknown): string | null {
  if (!json || typeof json !== "object") {
    return null;
  }

  const address = (json as { formattedAddress?: unknown }).formattedAddress;
  return typeof address === "string" && address.trim() ? address.trim() : null;
}

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
  return daysScheduleFilter([day]);
}

function daysScheduleFilter(days: number[]): SQL {
  return exists(
    db
      .select({ one: sql`1` })
      .from(dealSchedule)
      .where(
        and(
          eq(dealSchedule.dealId, deal.id),
          inArray(dealSchedule.dayOfWeek, days),
        ),
      ),
  );
}

function timeRangeScheduleFilter(
  days: number[] | undefined,
  startMinute: number,
  endMinute: number,
): SQL {
  const dayFilter =
    days && days.length > 0
      ? inArray(dealSchedule.dayOfWeek, days)
      : undefined;

  return exists(
    db
      .select({ one: sql`1` })
      .from(dealSchedule)
      .where(
        and(
          eq(dealSchedule.dealId, deal.id),
          dayFilter,
          sql`${dealSchedule.startMinute} < ${endMinute}`,
          sql`${dealSchedule.endMinute} > ${startMinute}`,
        ),
      ),
  );
}

function textSearchFilter(query: string): SQL {
  return sql`${dealSearchVector} @@ plainto_tsquery('english', ${query})`;
}

const dealSearchVector = sql`to_tsvector('english', coalesce(${deal.title}, '') || ' ' || coalesce(${deal.details}, '') || ' ' || coalesce(${deal.conditions}, ''))`;

const DEFAULT_NEAR_ME_RADIUS_KM = 30;

function distanceKmExpression(lat: number, lng: number): SQL {
  return sql`(
    6371 * acos(
      least(1.0, greatest(-1.0,
        cos(radians(${lat})) * cos(radians(${venue.lat})) *
        cos(radians(${venue.lng}) - radians(${lng})) +
        sin(radians(${lat})) * sin(radians(${venue.lat}))
      ))
    )
  )`;
}

function nearLocationFilter(lat: number, lng: number, radiusKm: number): SQL {
  return sql`${distanceKmExpression(lat, lng)} <= ${radiusKm}`;
}

export async function searchSuburbs(
  query: string,
  limit = 20,
): Promise<SuburbSearchResult[]> {
  const trimmed = query.trim();

  if (!trimmed) {
    return db
      .select({
        id: suburb.id,
        name: suburb.name,
        postcode: suburb.postcode,
      })
      .from(suburb)
      .orderBy(suburb.name)
      .limit(limit);
  }

  return db
    .select({
      id: suburb.id,
      name: suburb.name,
      postcode: suburb.postcode,
    })
    .from(suburb)
    .where(
      or(
        ilike(suburb.name, `%${trimmed}%`),
        ilike(suburb.postcode, `%${trimmed}%`),
      ),
    )
    .orderBy(suburb.name)
    .limit(limit);
}

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
  days?: number[];
  suburbId?: number;
  lat?: number;
  lng?: number;
  radiusKm?: number;
  startMinute?: number;
  endMinute?: number;
  query?: string;
  activeNow?: boolean;
  limit?: number;
}): Promise<DealSearchResult[]> {
  const filters: SQL[] = [];
  const hasNearLocation =
    options.lat !== undefined && options.lng !== undefined;

  if (options.venueId !== undefined) {
    filters.push(eq(deal.venueId, options.venueId));
  }

  if (options.suburbId !== undefined) {
    filters.push(eq(venue.suburbId, options.suburbId));
  }

  if (hasNearLocation) {
    filters.push(
      nearLocationFilter(
        options.lat!,
        options.lng!,
        options.radiusKm ?? DEFAULT_NEAR_ME_RADIUS_KM,
      ),
    );
  }

  if (options.days !== undefined && options.days.length > 0) {
    if (
      options.startMinute !== undefined &&
      options.endMinute !== undefined
    ) {
      filters.push(
        timeRangeScheduleFilter(
          options.days,
          options.startMinute,
          options.endMinute,
        ),
      );
    } else {
      filters.push(daysScheduleFilter(options.days));
    }
  } else if (options.day !== undefined) {
    if (
      options.startMinute !== undefined &&
      options.endMinute !== undefined
    ) {
      filters.push(
        timeRangeScheduleFilter(
          [options.day],
          options.startMinute,
          options.endMinute,
        ),
      );
    } else {
      filters.push(dayScheduleFilter(options.day));
    }
  } else if (
    options.startMinute !== undefined &&
    options.endMinute !== undefined
  ) {
    filters.push(
      timeRangeScheduleFilter(
        undefined,
        options.startMinute,
        options.endMinute,
      ),
    );
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
      venueHeroImage: venue.heroImage,
      venueJson: venue.json,
    })
    .from(deal)
    .innerJoin(venue, eq(deal.venueId, venue.id))
    .where(filters.length > 0 ? and(...filters) : undefined)
    .orderBy(
      ...(hasNearLocation
        ? [distanceKmExpression(options.lat!, options.lng!), venue.name, deal.title]
        : [venue.name, deal.title]),
    )
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
      heroImage: row.venueHeroImage,
      formattedAddress: parseVenueFormattedAddress(row.venueJson),
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
