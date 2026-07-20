import { user } from "@/db/auth-schema";
import { relations, sql } from "drizzle-orm";
import {
  date,
  doublePrecision,
  index,
  integer,
  jsonb,
  pgTable,
  serial,
  text,
  timestamp,
  uniqueIndex,
} from "drizzle-orm/pg-core";

export const suburb = pgTable(
  "suburb",
  {
    id: serial("id").primaryKey(),
    name: text("name").notNull(),
    postcode: text("postcode"),
    state: text("state"),
    lat: doublePrecision("lat"),
    lng: doublePrecision("lng"),
    sqkm: doublePrecision("sqkm"),
    heroImage: text("hero_image"),
  },
  (table) => [
    uniqueIndex("suburb_name_postcode_idx").on(table.name, table.postcode),
  ],
);

export const venue = pgTable(
  "venue",
  {
    id: serial("id").primaryKey(),
    suburbId: integer("suburb_id").references(() => suburb.id, {
      onDelete: "set null",
    }),
    googleMapId: text("google_map_id").notNull().unique(),
    name: text("name").notNull(),
    lat: doublePrecision("lat").notNull(),
    lng: doublePrecision("lng").notNull(),
    websiteUri: text("website_uri"),
    heroImage: text("hero_image"),
    blurb: text("blurb"),
    googleRating: doublePrecision("google_rating"),
    lastCrawlDate: timestamp("last_crawl_date", { withTimezone: true }),
    json: jsonb("json").notNull(),
    syncedAt: timestamp("synced_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => [index("venue_name_idx").on(table.name)],
);

export const venueLinks = pgTable("venue_links", {
  venueId: integer("venue_id")
    .primaryKey()
    .references(() => venue.id, { onDelete: "cascade" }),
  whatsOn: text("whats_on"),
  instagram: text("instagram"),
  facebook: text("facebook"),
});

export const dealCreationSource = ["scraper", "user", "venue"] as const;
export type DealCreationSource = (typeof dealCreationSource)[number];

export const dealStatus = ["approved", "rejected", "new"] as const;
export type DealStatus = (typeof dealStatus)[number];

export const deal = pgTable(
  "deal",
  {
    id: serial("id").primaryKey(),
    venueId: integer("venue_id")
      .notNull()
      .references(() => venue.id, { onDelete: "cascade" }),
    sourceDealId: integer("source_deal_id"),
    creationSource: text("creation_source").notNull().default("scraper"),
    status: text("status").notNull().default("approved"),
    title: text("title"),
    imageUrl: text("image_url"),
    sourceUrl: text("source_url"),
    details: text("details"),
    conditions: text("conditions"),
    startDate: date("start_date"),
    endDate: date("end_date"),
    syncedAt: timestamp("synced_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => [
    index("deal_venue_id_idx").on(table.venueId),
    uniqueIndex("deal_venue_source_deal_id_idx").on(
      table.venueId,
      table.sourceDealId,
    ),
  ],
);

export const dealReportCategory = [
  "unavailable",
  "incorrect_schedule",
  "incorrect_description",
] as const;
export type DealReportCategory = (typeof dealReportCategory)[number];

export const dealReportStatus = ["new", "approved", "rejected"] as const;
export type DealReportStatus = (typeof dealReportStatus)[number];

export const dealReport = pgTable(
  "deal_report",
  {
    id: serial("id").primaryKey(),
    dealId: integer("deal_id")
      .notNull()
      .references(() => deal.id, { onDelete: "cascade" }),
    userId: text("user_id").references(() => user.id, { onDelete: "set null" }),
    category: text("category").notNull(),
    details: text("details"),
    status: text("status").notNull().default("new"),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => [
    index("deal_report_deal_id_idx").on(table.dealId),
    index("deal_report_user_id_idx").on(table.userId),
  ],
);

export const favoriteDeal = pgTable(
  "favorite_deal",
  {
    userId: text("user_id")
      .notNull()
      .references(() => user.id, { onDelete: "cascade" }),
    dealId: integer("deal_id")
      .notNull()
      .references(() => deal.id, { onDelete: "cascade" }),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => [
    uniqueIndex("favorite_deal_user_deal_idx").on(table.userId, table.dealId),
    index("favorite_deal_user_id_idx").on(table.userId),
  ],
);

export const dealSchedule = pgTable(
  "deal_schedule",
  {
    id: serial("id").primaryKey(),
    dealId: integer("deal_id")
      .notNull()
      .references(() => deal.id, { onDelete: "cascade" }),
    dayOfWeek: integer("day_of_week").notNull(),
    startMinute: integer("start_minute").notNull(),
    endMinute: integer("end_minute").notNull(),
  },
  (table) => [
    index("deal_schedule_day_time_idx").on(
      table.dayOfWeek,
      table.startMinute,
      table.endMinute,
    ),
    index("deal_schedule_deal_id_idx").on(table.dealId),
  ],
);

export const syncRun = pgTable("sync_run", {
  id: serial("id").primaryKey(),
  startedAt: timestamp("started_at", { withTimezone: true }).notNull(),
  finishedAt: timestamp("finished_at", { withTimezone: true }),
  mode: text("mode").notNull(),
  venuesSynced: integer("venues_synced").notNull().default(0),
  dealsSynced: integer("deals_synced").notNull().default(0),
  suburbsSynced: integer("suburbs_synced").notNull().default(0),
});

export const venueRelations = relations(venue, ({ one, many }) => ({
  suburb: one(suburb, {
    fields: [venue.suburbId],
    references: [suburb.id],
  }),
  links: one(venueLinks, {
    fields: [venue.id],
    references: [venueLinks.venueId],
  }),
  deals: many(deal),
}));

export const suburbRelations = relations(suburb, ({ many }) => ({
  venues: many(venue),
}));

export const venueLinksRelations = relations(venueLinks, ({ one }) => ({
  venue: one(venue, {
    fields: [venueLinks.venueId],
    references: [venue.id],
  }),
}));

export const dealRelations = relations(deal, ({ one, many }) => ({
  venue: one(venue, {
    fields: [deal.venueId],
    references: [venue.id],
  }),
  schedules: many(dealSchedule),
  reports: many(dealReport),
  favorites: many(favoriteDeal),
}));

export const dealReportRelations = relations(dealReport, ({ one }) => ({
  deal: one(deal, {
    fields: [dealReport.dealId],
    references: [deal.id],
  }),
  user: one(user, {
    fields: [dealReport.userId],
    references: [user.id],
  }),
}));

export const favoriteDealRelations = relations(favoriteDeal, ({ one }) => ({
  deal: one(deal, {
    fields: [favoriteDeal.dealId],
    references: [deal.id],
  }),
  user: one(user, {
    fields: [favoriteDeal.userId],
    references: [user.id],
  }),
}));

export const dealScheduleRelations = relations(dealSchedule, ({ one }) => ({
  deal: one(deal, {
    fields: [dealSchedule.dealId],
    references: [deal.id],
  }),
}));

export type Suburb = typeof suburb.$inferSelect;
export type Venue = typeof venue.$inferSelect;
export type VenueLinks = typeof venueLinks.$inferSelect;
export type Deal = typeof deal.$inferSelect;
export type DealSchedule = typeof dealSchedule.$inferSelect;
export type DealReport = typeof dealReport.$inferSelect;
export type FavoriteDeal = typeof favoriteDeal.$inferSelect;
export type SyncRun = typeof syncRun.$inferSelect;

/** Full-text search vector for deals (used in raw SQL queries). */
export const dealSearchVector = sql`to_tsvector('english', coalesce(${deal.title}, '') || ' ' || coalesce(${deal.details}, '') || ' ' || coalesce(${deal.conditions}, ''))`;
