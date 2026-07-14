import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import * as authSchema from "@/db/auth-schema";
import * as schema from "@/db/schema";

const fullSchema = { ...schema, ...authSchema };

type Db = ReturnType<typeof drizzle<typeof fullSchema>>;

function createDb(): Db {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error("DATABASE_URL is not set");
  }

  const client = postgres(connectionString, { max: 10 });
  return drizzle(client, { schema: fullSchema });
}

declare global {
  var __happyHourDb: Db | undefined;
}

function getDb(): Db {
  if (!globalThis.__happyHourDb) {
    globalThis.__happyHourDb = createDb();
  }
  return globalThis.__happyHourDb;
}

/** Lazily connects on first use so `next build` can import modules without a live DB. */
export const db: Db = new Proxy({} as Db, {
  get(_target, property, receiver) {
    const value = Reflect.get(getDb(), property, receiver);
    return typeof value === "function" ? value.bind(getDb()) : value;
  },
});
