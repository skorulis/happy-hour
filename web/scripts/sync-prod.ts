import { execSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadScriptEnv } from "../load-script-env";

process.env.SYNC_TARGET = "production";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const webRoot = path.join(scriptDir, "..");
process.chdir(webRoot);

loadScriptEnv();

const args = process.argv.slice(2);

for (let index = 0; index < args.length; index += 1) {
  const arg = args[index];
  if (arg === "--migrate") {
    continue;
  }
  if (arg === "--sqlite-path" && args[index + 1]) {
    process.env.SQLITE_PATH = args[index + 1];
    index += 1;
    continue;
  }
  if (arg.startsWith("--sqlite-path=")) {
    process.env.SQLITE_PATH = arg.slice("--sqlite-path=".length);
  }
}

if (!process.env.SQLITE_PATH?.trim()) {
  throw new Error(
    "SQLITE_PATH is not set. Add it to .env.local or pass --sqlite-path.",
  );
}

if (args.includes("--migrate")) {
  console.log("Running migrations against production…");
  execSync("npx drizzle-kit migrate", {
    stdio: "inherit",
    env: process.env,
    cwd: webRoot,
  });
}

const syncArgs = args.filter((arg) => arg !== "--migrate");
const syncCommand =
  syncArgs.length > 0
    ? `npx tsx scripts/sync-sqlite.ts ${syncArgs.map((arg) => JSON.stringify(arg)).join(" ")}`
    : "npx tsx scripts/sync-sqlite.ts";

console.log("Syncing DealScraper data to production…");
execSync(syncCommand, {
  stdio: "inherit",
  env: process.env,
  cwd: webRoot,
});
