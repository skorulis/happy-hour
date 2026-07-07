CREATE TABLE "deal_report" (
	"id" serial PRIMARY KEY NOT NULL,
	"deal_id" integer NOT NULL,
	"user_id" text,
	"category" text NOT NULL,
	"details" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "deal_report" ADD CONSTRAINT "deal_report_deal_id_deal_id_fk" FOREIGN KEY ("deal_id") REFERENCES "public"."deal"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "deal_report" ADD CONSTRAINT "deal_report_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "deal_report_deal_id_idx" ON "deal_report" USING btree ("deal_id");--> statement-breakpoint
CREATE INDEX "deal_report_user_id_idx" ON "deal_report" USING btree ("user_id");