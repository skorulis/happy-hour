import { loadScriptEnv } from "../load-script-env";

loadScriptEnv();
import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import * as schema from "../db/schema";
import { syncRegionGeo } from "./sync-region-geo";

async function main() {
  const databaseUrl = process.env.DATABASE_URL;

  if (!databaseUrl) {
    throw new Error("DATABASE_URL is not set");
  }

  const pgClient = postgres(databaseUrl, { max: 1 });
  const db = drizzle(pgClient, { schema });

  try {
    const { framed, cleared } = await syncRegionGeo(db);
    console.log("Region map framing updated");
    console.log(`  Regions framed: ${framed}`);
    console.log(`  Regions without suburb coordinates: ${cleared}`);
  } finally {
    await pgClient.end();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
