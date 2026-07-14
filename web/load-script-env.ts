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
        "DATABASE_URL is not set. Create web/.env.production.local pointing at production Postgres via an SSH tunnel.\n" +
          "  ssh -L 5433:127.0.0.1:5432 user@DROPLET_IP\n" +
          "  # DATABASE_URL=postgresql://happyhour:PASSWORD@localhost:5433/happyhour\n" +
          "See web/README.md (Deploy / sync production).",
      );
    }
    config({ path: ".env.local" });
    return;
  }

  config({ path: ".env" });
  config({ path: ".env.local", override: true });
}
