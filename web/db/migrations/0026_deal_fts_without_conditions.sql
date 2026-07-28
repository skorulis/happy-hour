DROP INDEX IF EXISTS "deal_fts_idx";--> statement-breakpoint
CREATE INDEX "deal_fts_idx" ON "deal" USING gin (
	to_tsvector('english', coalesce("title", '') || ' ' || coalesce("details", ''))
);
