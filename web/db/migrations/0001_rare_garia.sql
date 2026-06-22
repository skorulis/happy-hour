CREATE TABLE "suburb" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"postcode" text
);
--> statement-breakpoint
ALTER TABLE "venue" ADD COLUMN "suburb_id" integer;--> statement-breakpoint
CREATE UNIQUE INDEX "suburb_name_postcode_idx" ON "suburb" USING btree ("name","postcode");--> statement-breakpoint
ALTER TABLE "venue" ADD CONSTRAINT "venue_suburb_id_suburb_id_fk" FOREIGN KEY ("suburb_id") REFERENCES "public"."suburb"("id") ON DELETE set null ON UPDATE no action;