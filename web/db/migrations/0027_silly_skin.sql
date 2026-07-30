CREATE TABLE "venue_feature" (
	"id" serial PRIMARY KEY NOT NULL,
	"venue_id" integer NOT NULL,
	"feature" text NOT NULL
);
--> statement-breakpoint
ALTER TABLE "venue_feature" ADD CONSTRAINT "venue_feature_venue_id_venue_id_fk" FOREIGN KEY ("venue_id") REFERENCES "public"."venue"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "venue_feature_venue_feature_idx" ON "venue_feature" USING btree ("venue_id","feature");--> statement-breakpoint
CREATE INDEX "venue_feature_venue_id_idx" ON "venue_feature" USING btree ("venue_id");