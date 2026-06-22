CREATE TABLE "deal" (
	"id" serial PRIMARY KEY NOT NULL,
	"venue_id" integer NOT NULL,
	"title" text,
	"image_url" text,
	"source_url" text,
	"details" text,
	"conditions" text,
	"synced_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "deal_schedule" (
	"id" serial PRIMARY KEY NOT NULL,
	"deal_id" integer NOT NULL,
	"day_of_week" integer NOT NULL,
	"start_minute" integer NOT NULL,
	"end_minute" integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE "venue" (
	"id" serial PRIMARY KEY NOT NULL,
	"google_map_id" text NOT NULL,
	"name" text NOT NULL,
	"lat" double precision NOT NULL,
	"lng" double precision NOT NULL,
	"website_uri" text,
	"last_crawl_date" timestamp with time zone,
	"json" jsonb NOT NULL,
	"synced_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "venue_google_map_id_unique" UNIQUE("google_map_id")
);
--> statement-breakpoint
CREATE TABLE "venue_links" (
	"venue_id" integer PRIMARY KEY NOT NULL,
	"whats_on" text,
	"instagram" text,
	"facebook" text
);
--> statement-breakpoint
ALTER TABLE "deal" ADD CONSTRAINT "deal_venue_id_venue_id_fk" FOREIGN KEY ("venue_id") REFERENCES "public"."venue"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "deal_schedule" ADD CONSTRAINT "deal_schedule_deal_id_deal_id_fk" FOREIGN KEY ("deal_id") REFERENCES "public"."deal"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "venue_links" ADD CONSTRAINT "venue_links_venue_id_venue_id_fk" FOREIGN KEY ("venue_id") REFERENCES "public"."venue"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "deal_venue_id_idx" ON "deal" USING btree ("venue_id");--> statement-breakpoint
CREATE INDEX "deal_schedule_day_time_idx" ON "deal_schedule" USING btree ("day_of_week","start_minute","end_minute");--> statement-breakpoint
CREATE INDEX "deal_schedule_deal_id_idx" ON "deal_schedule" USING btree ("deal_id");--> statement-breakpoint
CREATE INDEX "venue_name_idx" ON "venue" USING btree ("name");--> statement-breakpoint
CREATE EXTENSION IF NOT EXISTS pg_trgm;--> statement-breakpoint
CREATE INDEX "venue_name_trgm_idx" ON "venue" USING gin ("name" gin_trgm_ops);--> statement-breakpoint
CREATE INDEX "deal_fts_idx" ON "deal" USING gin (
	to_tsvector('english', coalesce("title", '') || ' ' || coalesce("details", '') || ' ' || coalesce("conditions", ''))
);