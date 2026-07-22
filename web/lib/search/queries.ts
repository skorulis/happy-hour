import {
  and,
  count,
  countDistinct,
  desc,
  eq,
  exists,
  gte,
  ilike,
  inArray,
  isNull,
  lte,
  ne,
  or,
  sql,
  type SQL,
} from "drizzle-orm";
import { db } from "@/lib/db";
import type { MapBounds } from "@/lib/search/bounds";
import {
  currentCalendarWeekday,
  currentMinuteOfDay,
} from "@/lib/search/schedule";
import { expandKeywords } from "@data/products";
import {
  NEAR_ME_RADIUS_KM,
  nearbySuburbRadiusKm,
} from "@/lib/search/nearby-radius";
import { parseWhatTokens } from "@/lib/search/url";
import {
  parseSuburbWhereSlug,
  regionSlug,
  slugify,
  UNKNOWN_SUBURB_SLUG,
} from "@/lib/search/slugs";
import {
  deal,
  dealSchedule,
  geographicRegion,
  suburb,
  venue,
  venueLinks,
} from "@/db/schema";
import { getDealIdsWithOpenReports } from "@/lib/reports/queries";

export type SuburbSearchResult = {
  id: number;
  name: string;
  postcode: string | null;
  lat?: number | null;
  lng?: number | null;
  sqkm?: number | null;
  heroImage?: string | null;
};

export type PopularSuburb = {
  id: number;
  name: string;
  postcode: string | null;
  heroImage: string | null;
  dealCount: number;
  venueCount: number;
};

export type VenueSearchResult = {
  id: number;
  name: string;
  suburbName: string | null;
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
  startDate: string | null;
  endDate: string | null;
  /** True when the deal has an unresolved user report (venue pages). */
  hasOpenReport?: boolean;
  venue: {
    id: number;
    name: string;
    suburbName: string | null;
    lat: number;
    lng: number;
    websiteUri: string | null;
    heroImage: string | null;
    formattedAddress: string | null;
    distanceKm?: number;
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
  googleMapId: string;
  heroImage: string | null;
  blurb: string | null;
  suburbName: string | null;
  links: {
    whatsOn: string | null;
    instagram: string | null;
    facebook: string | null;
  } | null;
  deals: DealSearchResult[];
};

function previousCalendarWeekday(day: number): number {
  return day === 1 ? 7 : day - 1;
}

function activeNowScheduleFilter(now = new Date()): SQL {
  const day = currentCalendarWeekday(now);
  const minute = currentMinuteOfDay(now);
  const previousDay = previousCalendarWeekday(day);

  return exists(
    db
      .select({ one: sql`1` })
      .from(dealSchedule)
      .where(
        and(
          eq(dealSchedule.dealId, deal.id),
          or(
            and(
              eq(dealSchedule.dayOfWeek, day),
              sql`${dealSchedule.startMinute} <= ${minute}`,
              sql`${dealSchedule.endMinute} > ${minute}`,
            ),
            and(
              eq(dealSchedule.dayOfWeek, previousDay),
              sql`${dealSchedule.endMinute} > ${1440}`,
              sql`${minute} < ${dealSchedule.endMinute} - ${1440}`,
            ),
          ),
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

function scheduleTimeFilter(
  days: number[] | undefined,
  startMinute?: number,
  endMinute?: number,
): SQL | undefined {
  if (startMinute === undefined && endMinute === undefined) {
    return undefined;
  }

  const dayFilter =
    days && days.length > 0
      ? inArray(dealSchedule.dayOfWeek, days)
      : undefined;

  const timeConditions: SQL[] = [];

  if (startMinute !== undefined && endMinute !== undefined) {
    if (endMinute < startMinute) {
      return undefined;
    }

    if (startMinute === endMinute) {
      timeConditions.push(
        sql`${dealSchedule.startMinute} <= ${startMinute}`,
        sql`${dealSchedule.endMinute} > ${startMinute}`,
      );
    } else {
      timeConditions.push(
        sql`${dealSchedule.startMinute} < ${endMinute}`,
        sql`${dealSchedule.endMinute} > ${startMinute}`,
      );
    }
  } else if (startMinute !== undefined) {
    timeConditions.push(sql`${dealSchedule.endMinute} > ${startMinute}`);
  } else {
    timeConditions.push(sql`${dealSchedule.startMinute} < ${endMinute}`);
  }

  return exists(
    db
      .select({ one: sql`1` })
      .from(dealSchedule)
      .where(
        and(
          eq(dealSchedule.dealId, deal.id),
          dayFilter,
          ...timeConditions,
        ),
      ),
  );
}

function textSearchFilter(query: string): SQL {
  return sql`${dealSearchVector} @@ plainto_tsquery('english', ${query})`;
}

function textSearchFilterForWhatQuery(query: string): SQL {
  const tokens = parseWhatTokens(query);
  if (tokens.length === 0) {
    return textSearchFilter(query);
  }

  const terms = expandKeywords(tokens);
  if (terms.length === 1) {
    return textSearchFilter(terms[0]);
  }

  return or(...terms.map((term) => textSearchFilter(term)))!;
}

const dealSearchVector = sql`to_tsvector('english', coalesce(${deal.title}, '') || ' ' || coalesce(${deal.details}, '') || ' ' || coalesce(${deal.conditions}, ''))`;


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

function boundsFilter(bounds: MapBounds): SQL {
  return and(
    gte(venue.lat, bounds.south),
    lte(venue.lat, bounds.north),
    gte(venue.lng, bounds.west),
    lte(venue.lng, bounds.east),
  )!;
}

export async function searchSuburbs(
  query: string,
  limit = 20,
): Promise<SuburbSearchResult[]> {
  const trimmed = query.trim();

  const baseQuery = db
    .select({
      id: suburb.id,
      name: suburb.name,
      postcode: suburb.postcode,
    })
    .from(suburb)
    .leftJoin(venue, eq(venue.suburbId, suburb.id))
    .leftJoin(deal, eq(deal.venueId, venue.id))
    .$dynamic();

  const filtered = trimmed
    ? baseQuery.where(
        or(
          ilike(suburb.name, `%${trimmed}%`),
          ilike(suburb.postcode, `%${trimmed}%`),
        ),
      )
    : baseQuery;

  return filtered
    .groupBy(suburb.id, suburb.name, suburb.postcode)
    .orderBy(desc(count(deal.id)), suburb.name)
    .limit(limit);
}

export type RegionWithCounts = {
  id: number;
  name: string;
  slug: string;
  dealCount: number;
  venueCount: number;
};

export type RegionSearchResult = {
  id: number;
  name: string;
};

export type ListPopularSuburbsOptions = {
  days?: number[];
  startMinute?: number;
  endMinute?: number;
  query?: string;
  regionId?: number;
};

export type ListAllSuburbsOptions = {
  regionId?: number;
};

export async function listPopularSuburbs(
  limit?: number,
  options: ListPopularSuburbsOptions = {},
): Promise<PopularSuburb[]> {
  const dealCount = count(deal.id);
  const venueCount = countDistinct(venue.id);
  const filters: SQL[] = [eq(deal.status, "approved")];

  if (options.days !== undefined && options.days.length > 0) {
    const timeFilter = scheduleTimeFilter(
      options.days,
      options.startMinute,
      options.endMinute,
    );
    if (timeFilter) {
      filters.push(timeFilter);
    } else {
      filters.push(daysScheduleFilter(options.days));
    }
  } else {
    const timeFilter = scheduleTimeFilter(
      undefined,
      options.startMinute,
      options.endMinute,
    );
    if (timeFilter) {
      filters.push(timeFilter);
    }
  }

  const trimmedQuery = options.query?.trim();
  if (trimmedQuery) {
    filters.push(textSearchFilterForWhatQuery(trimmedQuery));
  }

  if (options.regionId !== undefined) {
    filters.push(eq(suburb.regionId, options.regionId));
  }

  const query = db
    .select({
      id: suburb.id,
      name: suburb.name,
      postcode: suburb.postcode,
      heroImage: suburb.heroImage,
      dealCount,
      venueCount,
    })
    .from(suburb)
    .innerJoin(venue, eq(venue.suburbId, suburb.id))
    .innerJoin(deal, eq(deal.venueId, venue.id))
    .where(and(...filters))
    .groupBy(suburb.id, suburb.name, suburb.postcode, suburb.heroImage)
    .orderBy(desc(dealCount), suburb.name);

  return limit === undefined ? query : query.limit(limit);
}

/** Every suburb, including those with no deals (dealCount may be 0). */
export async function listAllSuburbs(
  options: ListAllSuburbsOptions = {},
): Promise<PopularSuburb[]> {
  const dealCount = count(deal.id);
  const venueCount = countDistinct(venue.id);

  let query = db
    .select({
      id: suburb.id,
      name: suburb.name,
      postcode: suburb.postcode,
      heroImage: suburb.heroImage,
      dealCount,
      venueCount,
    })
    .from(suburb)
    .leftJoin(venue, eq(venue.suburbId, suburb.id))
    .leftJoin(deal, eq(deal.venueId, venue.id))
    .$dynamic();

  if (options.regionId !== undefined) {
    query = query.where(eq(suburb.regionId, options.regionId));
  }

  return query
    .groupBy(suburb.id, suburb.name, suburb.postcode, suburb.heroImage)
    .orderBy(desc(dealCount), suburb.name);
}

export async function listRegions(): Promise<RegionWithCounts[]> {
  const dealCount = count(deal.id);
  const venueCount = countDistinct(venue.id);

  const rows = await db
    .select({
      id: geographicRegion.id,
      name: geographicRegion.name,
      dealCount,
      venueCount,
    })
    .from(geographicRegion)
    .leftJoin(suburb, eq(suburb.regionId, geographicRegion.id))
    .leftJoin(venue, eq(venue.suburbId, suburb.id))
    .leftJoin(
      deal,
      and(eq(deal.venueId, venue.id), eq(deal.status, "approved")),
    )
    .groupBy(geographicRegion.id, geographicRegion.name)
    .orderBy(desc(dealCount), geographicRegion.name);

  return rows.map((row) => ({
    ...row,
    slug: regionSlug(row.name),
  }));
}

export async function findRegionBySlug(
  slug: string,
): Promise<RegionSearchResult | null> {
  const normalized = slug.trim().toLowerCase();
  if (!normalized) {
    return null;
  }

  const regions = await db
    .select({ id: geographicRegion.id, name: geographicRegion.name })
    .from(geographicRegion);

  return regions.find((region) => regionSlug(region.name) === normalized) ?? null;
}

export async function findSuburbByWhereSlug(
  whereSlug: string,
): Promise<SuburbSearchResult | null> {
  const { nameSlug, postcode } = parseSuburbWhereSlug(whereSlug);
  if (!nameSlug) {
    return null;
  }

  const candidates = await db
    .select({
      id: suburb.id,
      name: suburb.name,
      postcode: suburb.postcode,
      lat: suburb.lat,
      lng: suburb.lng,
      sqkm: suburb.sqkm,
      heroImage: suburb.heroImage,
    })
    .from(suburb)
    .where(postcode === null ? isNull(suburb.postcode) : eq(suburb.postcode, postcode));

  return (
    candidates.find((candidate) => slugify(candidate.name) === nameSlug) ?? null
  );
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
        suburbName: suburb.name,
        lat: venue.lat,
        lng: venue.lng,
        websiteUri: venue.websiteUri,
      })
      .from(venue)
      .leftJoin(suburb, eq(venue.suburbId, suburb.id))
      .orderBy(venue.name)
      .limit(limit);
  }

  return db
    .select({
      id: venue.id,
      name: venue.name,
      suburbName: suburb.name,
      lat: venue.lat,
      lng: venue.lng,
      websiteUri: venue.websiteUri,
    })
    .from(venue)
    .leftJoin(suburb, eq(venue.suburbId, suburb.id))
    .where(
      or(
        ilike(venue.name, `%${trimmed}%`),
        sql`similarity(${venue.name}, ${trimmed}) > 0.2`,
      ),
    )
    .orderBy(sql`similarity(${venue.name}, ${trimmed}) DESC`, venue.name)
    .limit(limit);
}

export type SearchDealsOptions = {
  venueId?: number;
  day?: number;
  days?: number[];
  suburbId?: number;
  excludeSuburbId?: number;
  lat?: number;
  lng?: number;
  radiusKm?: number;
  bounds?: MapBounds;
  startMinute?: number;
  endMinute?: number;
  query?: string;
  activeNow?: boolean;
  limit?: number;
};

export async function searchDeals(
  options: SearchDealsOptions,
): Promise<DealSearchResult[]> {
  const filters: SQL[] = [eq(deal.status, "approved")];
  const hasBounds = options.bounds !== undefined;
  const hasNearLocation =
    !hasBounds &&
    options.lat !== undefined &&
    options.lng !== undefined;

  if (options.venueId !== undefined) {
    filters.push(eq(deal.venueId, options.venueId));
  }

  if (hasBounds) {
    filters.push(boundsFilter(options.bounds!));
  } else if (options.suburbId !== undefined) {
    filters.push(eq(venue.suburbId, options.suburbId));
  }

  if (options.excludeSuburbId !== undefined) {
    filters.push(
      or(
        isNull(venue.suburbId),
        ne(venue.suburbId, options.excludeSuburbId),
      )!,
    );
  }

  if (hasNearLocation) {
    filters.push(
      nearLocationFilter(
        options.lat!,
        options.lng!,
        options.radiusKm ?? NEAR_ME_RADIUS_KM,
      ),
    );
  }

  if (options.days !== undefined && options.days.length > 0) {
    const timeFilter = scheduleTimeFilter(
      options.days,
      options.startMinute,
      options.endMinute,
    );
    if (timeFilter) {
      filters.push(timeFilter);
    } else {
      filters.push(daysScheduleFilter(options.days));
    }
  } else if (options.day !== undefined) {
    const timeFilter = scheduleTimeFilter(
      [options.day],
      options.startMinute,
      options.endMinute,
    );
    if (timeFilter) {
      filters.push(timeFilter);
    } else {
      filters.push(dayScheduleFilter(options.day));
    }
  } else {
    const timeFilter = scheduleTimeFilter(
      undefined,
      options.startMinute,
      options.endMinute,
    );
    if (timeFilter) {
      filters.push(timeFilter);
    }
  }

  if (options.activeNow) {
    filters.push(activeNowScheduleFilter());
  }

  const trimmedQuery = options.query?.trim();
  if (trimmedQuery) {
    filters.push(textSearchFilterForWhatQuery(trimmedQuery));
  }

  const dealSelectFields = {
    dealId: deal.id,
    title: deal.title,
    details: deal.details,
    conditions: deal.conditions,
    imageUrl: deal.imageUrl,
    sourceUrl: deal.sourceUrl,
    startDate: deal.startDate,
    endDate: deal.endDate,
    venueId: venue.id,
    venueName: venue.name,
    venueSuburbName: suburb.name,
    venueLat: venue.lat,
    venueLng: venue.lng,
    venueWebsiteUri: venue.websiteUri,
    venueHeroImage: venue.heroImage,
    venueJson: venue.json,
  };

  const rows = await db
    .select(
      hasNearLocation
        ? {
            ...dealSelectFields,
            distanceKm: sql<number>`${distanceKmExpression(options.lat!, options.lng!)}`,
          }
        : dealSelectFields,
    )
    .from(deal)
    .innerJoin(venue, eq(deal.venueId, venue.id))
    .leftJoin(suburb, eq(venue.suburbId, suburb.id))
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
    startDate: row.startDate,
    endDate: row.endDate,
    venue: {
      id: row.venueId,
      name: row.venueName,
      suburbName: row.venueSuburbName,
      lat: row.venueLat,
      lng: row.venueLng,
      websiteUri: row.venueWebsiteUri,
      heroImage: row.venueHeroImage,
      formattedAddress: parseVenueFormattedAddress(row.venueJson),
      ...("distanceKm" in row && row.distanceKm != null
        ? { distanceKm: Number(row.distanceKm) }
        : {}),
    },
    schedules: schedulesByDeal.get(row.dealId) ?? [],
  }));
}

export async function getDealsByIds(
  dealIds: number[],
): Promise<DealSearchResult[]> {
  if (dealIds.length === 0) {
    return [];
  }

  const rows = await db
    .select({
      dealId: deal.id,
      title: deal.title,
      details: deal.details,
      conditions: deal.conditions,
      imageUrl: deal.imageUrl,
      sourceUrl: deal.sourceUrl,
      startDate: deal.startDate,
      endDate: deal.endDate,
      venueId: venue.id,
      venueName: venue.name,
      venueSuburbName: suburb.name,
      venueLat: venue.lat,
      venueLng: venue.lng,
      venueWebsiteUri: venue.websiteUri,
      venueHeroImage: venue.heroImage,
      venueJson: venue.json,
    })
    .from(deal)
    .innerJoin(venue, eq(deal.venueId, venue.id))
    .leftJoin(suburb, eq(venue.suburbId, suburb.id))
    .where(and(inArray(deal.id, dealIds), eq(deal.status, "approved")))
    .orderBy(venue.name, deal.title);

  if (rows.length === 0) {
    return [];
  }

  const matchedDealIds = rows.map((row) => row.dealId);
  const schedules = await db
    .select()
    .from(dealSchedule)
    .where(inArray(dealSchedule.dealId, matchedDealIds))
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
    startDate: row.startDate,
    endDate: row.endDate,
    venue: {
      id: row.venueId,
      name: row.venueName,
      suburbName: row.venueSuburbName,
      lat: row.venueLat,
      lng: row.venueLng,
      websiteUri: row.venueWebsiteUri,
      heroImage: row.venueHeroImage,
      formattedAddress: parseVenueFormattedAddress(row.venueJson),
    },
    schedules: schedulesByDeal.get(row.dealId) ?? [],
  }));
}

export async function searchDealsForSuburb(
  options: Omit<
    SearchDealsOptions,
    "suburbId" | "lat" | "lng" | "radiusKm" | "excludeSuburbId"
  > & { suburbId: number },
): Promise<{ deals: DealSearchResult[]; nearbyDeals: DealSearchResult[] }> {
  const { suburbId, ...sharedOptions } = options;

  const deals = await searchDeals({ ...sharedOptions, suburbId });

  const [suburbRow] = await db
    .select({ lat: suburb.lat, lng: suburb.lng, sqkm: suburb.sqkm })
    .from(suburb)
    .where(eq(suburb.id, suburbId))
    .limit(1);

  if (
    !suburbRow ||
    suburbRow.lat === null ||
    suburbRow.lng === null
  ) {
    return { deals, nearbyDeals: [] };
  }

  const nearbyDeals = await searchDeals({
    ...sharedOptions,
    lat: suburbRow.lat,
    lng: suburbRow.lng,
    radiusKm: nearbySuburbRadiusKm(suburbRow.sqkm),
    excludeSuburbId: suburbId,
  });

  return { deals, nearbyDeals };
}

async function buildVenueDetail(
  venueRow: typeof venue.$inferSelect,
  suburbName: string | null,
): Promise<VenueDetailResult> {
  const [linksRow] = await db
    .select()
    .from(venueLinks)
    .where(eq(venueLinks.venueId, venueRow.id))
    .limit(1);

  const deals = await searchDeals({ venueId: venueRow.id, limit: 500 });
  const openReportDealIds = await getDealIdsWithOpenReports(
    deals.map((dealRow) => dealRow.id),
  );

  return {
    id: venueRow.id,
    name: venueRow.name,
    googleMapId: venueRow.googleMapId,
    suburbName,
    lat: venueRow.lat,
    lng: venueRow.lng,
    websiteUri: venueRow.websiteUri,
    heroImage: venueRow.heroImage,
    blurb: venueRow.blurb,
    links: linksRow
      ? {
          whatsOn: linksRow.whatsOn,
          instagram: linksRow.instagram,
          facebook: linksRow.facebook,
        }
      : null,
    deals: deals.map((dealRow) =>
      openReportDealIds.has(dealRow.id)
        ? { ...dealRow, hasOpenReport: true }
        : dealRow,
    ),
  };
}

export async function getVenueDetail(
  venueId: number,
): Promise<VenueDetailResult | null> {
  const [row] = await db
    .select({
      venue: venue,
      suburbName: suburb.name,
    })
    .from(venue)
    .leftJoin(suburb, eq(venue.suburbId, suburb.id))
    .where(eq(venue.id, venueId))
    .limit(1);

  if (!row) {
    return null;
  }

  return buildVenueDetail(row.venue, row.suburbName);
}

export async function getVenueDetailBySlug(
  suburbSlug: string,
  venueSlug: string,
): Promise<VenueDetailResult | null> {
  let venueRows: Array<typeof venue.$inferSelect>;

  if (suburbSlug === UNKNOWN_SUBURB_SLUG) {
    venueRows = await db.select().from(venue).where(isNull(venue.suburbId));
  } else {
    const suburbs = await db.select().from(suburb);
    const matchingSuburbIds = suburbs
      .filter((row) => slugify(row.name) === suburbSlug)
      .map((row) => row.id);

    if (matchingSuburbIds.length === 0) {
      return null;
    }

    venueRows = await db
      .select()
      .from(venue)
      .where(inArray(venue.suburbId, matchingSuburbIds));
  }

  const matchingVenues = venueRows.filter(
    (row) => slugify(row.name) === venueSlug,
  );

  if (matchingVenues.length === 0) {
    return null;
  }

  if (matchingVenues.length > 1) {
    return null;
  }

  const venueRow = matchingVenues[0];
  const suburbName =
    venueRow.suburbId === null
      ? null
      : (
          await db
            .select({ name: suburb.name })
            .from(suburb)
            .where(eq(suburb.id, venueRow.suburbId))
            .limit(1)
        )[0]?.name ?? null;

  return buildVenueDetail(venueRow, suburbName);
}

export type VenueSitemapRow = {
  name: string;
  suburbName: string | null;
  syncedAt: Date;
  lastCrawlDate: Date | null;
};

export async function getAllVenuesForSitemap(): Promise<VenueSitemapRow[]> {
  return db
    .select({
      name: venue.name,
      suburbName: suburb.name,
      syncedAt: venue.syncedAt,
      lastCrawlDate: venue.lastCrawlDate,
    })
    .from(venue)
    .leftJoin(suburb, eq(venue.suburbId, suburb.id))
    .orderBy(venue.name);
}

export type SuburbSitemapRow = {
  name: string;
  postcode: string | null;
};

export async function getAllSuburbsForSitemap(): Promise<SuburbSitemapRow[]> {
  return db
    .select({
      name: suburb.name,
      postcode: suburb.postcode,
    })
    .from(suburb)
    .orderBy(suburb.name);
}
