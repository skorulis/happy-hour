import { defineConfig } from "drizzle-kit";
import { loadScriptEnv } from "./load-script-env";

loadScriptEnv();

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error(
    "DATABASE_URL is not set. Copy .env.example to .env.local in the web/ directory.",
  );
}

export default defineConfig({
  schema: ["./db/schema.ts", "./db/auth-schema.ts"],
  out: "./db/migrations",
  dialect: "postgresql",
  dbCredentials: {
    url: databaseUrl,
  },
});
