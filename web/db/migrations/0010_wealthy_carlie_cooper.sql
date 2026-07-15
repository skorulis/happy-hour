CREATE TABLE "sync_run" (
	"id" serial PRIMARY KEY NOT NULL,
	"started_at" timestamp with time zone NOT NULL,
	"finished_at" timestamp with time zone,
	"mode" text NOT NULL,
	"venues_synced" integer DEFAULT 0 NOT NULL,
	"deals_synced" integer DEFAULT 0 NOT NULL,
	"suburbs_synced" integer DEFAULT 0 NOT NULL
);
