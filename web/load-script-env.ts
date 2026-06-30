import { config } from "dotenv";

/**
 * Loads env for CLI scripts (sync, migrate, import-suburbs).
 *
 * Default: `.env` then `.env.local` (local dev overrides).
 *
 * When `SYNC_TARGET=production`: loads `.env.production.local` for
 * `DATABASE_URL`, then `.env.local` for `SQLITE_PATH` without overriding
 * the production database URL.
 */
export function loadScriptEnv(): void {
  if (process.env.SYNC_TARGET === "production") {
    config({ path: ".env.production.local" });
    if (!process.env.DATABASE_URL?.trim()) {
      throw new Error(
        "DATABASE_URL is not set. Create web/.env.production.local with your Neon pooled connection string.\n" +
          "  cp .env.example .env.production.local\n" +
          "Or run: npx vercel env pull .env.production.local",
      );
    }
    config({ path: ".env.local" });
    return;
  }

  config({ path: ".env" });
  config({ path: ".env.local", override: true });
}
