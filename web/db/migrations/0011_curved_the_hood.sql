CREATE TABLE "favorite_deal" (
	"user_id" text NOT NULL,
	"deal_id" integer NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "favorite_deal" ADD CONSTRAINT "favorite_deal_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "favorite_deal" ADD CONSTRAINT "favorite_deal_deal_id_deal_id_fk" FOREIGN KEY ("deal_id") REFERENCES "public"."deal"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "favorite_deal_user_deal_idx" ON "favorite_deal" USING btree ("user_id","deal_id");--> statement-breakpoint
CREATE INDEX "favorite_deal_user_id_idx" ON "favorite_deal" USING btree ("user_id");