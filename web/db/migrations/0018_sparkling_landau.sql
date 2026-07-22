CREATE TABLE "country" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"iso3" text NOT NULL,
	CONSTRAINT "country_iso3_unique" UNIQUE("iso3")
);
--> statement-breakpoint
CREATE TABLE "geographic_region" (
	"id" serial PRIMARY KEY NOT NULL,
	"country_id" integer NOT NULL,
	"name" text NOT NULL
);
--> statement-breakpoint
ALTER TABLE "suburb" ADD COLUMN "region_id" integer;--> statement-breakpoint
ALTER TABLE "geographic_region" ADD CONSTRAINT "geographic_region_country_id_country_id_fk" FOREIGN KEY ("country_id") REFERENCES "public"."country"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "geographic_region_country_name_idx" ON "geographic_region" USING btree ("country_id","name");--> statement-breakpoint
ALTER TABLE "suburb" ADD CONSTRAINT "suburb_region_id_geographic_region_id_fk" FOREIGN KEY ("region_id") REFERENCES "public"."geographic_region"("id") ON DELETE set null ON UPDATE no action;