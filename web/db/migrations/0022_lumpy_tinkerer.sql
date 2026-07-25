CREATE TABLE "search_queries" (
	"id" serial PRIMARY KEY NOT NULL,
	"user_id" text,
	"type" text NOT NULL,
	"suburb_id" integer,
	"day" smallint,
	"products" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "search_queries" ADD CONSTRAINT "search_queries_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "search_queries" ADD CONSTRAINT "search_queries_suburb_id_suburb_id_fk" FOREIGN KEY ("suburb_id") REFERENCES "public"."suburb"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "search_queries_user_id_idx" ON "search_queries" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "search_queries_suburb_id_idx" ON "search_queries" USING btree ("suburb_id");--> statement-breakpoint
CREATE INDEX "search_queries_created_at_idx" ON "search_queries" USING btree ("created_at");