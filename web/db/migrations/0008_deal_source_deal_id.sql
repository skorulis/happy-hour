ALTER TABLE "deal" ADD COLUMN "source_deal_id" integer;--> statement-breakpoint
CREATE UNIQUE INDEX "deal_venue_source_deal_id_idx" ON "deal" USING btree ("venue_id","source_deal_id");