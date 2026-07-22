CREATE TABLE "venue_ownership" (
	"user_id" text NOT NULL,
	"venue_id" integer NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "venue_ownership" ADD CONSTRAINT "venue_ownership_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "venue_ownership" ADD CONSTRAINT "venue_ownership_venue_id_venue_id_fk" FOREIGN KEY ("venue_id") REFERENCES "public"."venue"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "venue_ownership_user_venue_idx" ON "venue_ownership" USING btree ("user_id","venue_id");--> statement-breakpoint
CREATE INDEX "venue_ownership_user_id_idx" ON "venue_ownership" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "venue_ownership_venue_id_idx" ON "venue_ownership" USING btree ("venue_id");