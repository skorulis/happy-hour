import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import * as authSchema from "@/db/auth-schema";
import * as schema from "@/db/schema";

const fullSchema = { ...schema, ...authSchema };

function createDb() {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error("DATABASE_URL is not set");
  }

  const client = postgres(connectionString, { max: 10 });
  return drizzle(client, { schema: fullSchema });
}

declare global {
  var __happyHourDb: ReturnType<typeof createDb> | undefined;
}

export const db = globalThis.__happyHourDb ?? createDb();

if (process.env.NODE_ENV !== "production") {
  globalThis.__happyHourDb = db;
}
