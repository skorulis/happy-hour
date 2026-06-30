# Happy Hour Web

Next.js website that serves deal search results from PostgreSQL. Approved deals are synced from the DealScraper SQLite database — see the [root README](../README.md) for the full data flow.

## Prerequisites

- Node.js 20+
- Docker (for local PostgreSQL)

## Database setup

From this directory, start the Postgres container:

```bash
docker compose up -d
```

This runs Postgres 16 with:

| Setting | Value |
|---------|-------|
| Host port | `5433` (mapped to container port 5432) |
| Database | `happyhour` |
| User | `happyhour` |
| Password | `happyhour` |

Port **5433** is used locally to avoid conflicting with other Postgres instances on 5432.

Copy the environment file and confirm `DATABASE_URL` points at the Docker instance:

```bash
cp .env.example .env.local
```

The default connection string is:

```text
postgresql://happyhour:happyhour@localhost:5433/happyhour
```

Apply the schema:

```bash
npm install
npm run db:migrate
```

Check that Postgres is running:

```bash
docker compose ps
```

## Running the app

Sync approved deals from DealScraper (set `SQLITE_PATH` in `.env.local` first):

```bash
npm run sync
```

### Sync production (Neon)

Create `.env.production.local` with your Neon **pooled** `DATABASE_URL` (see `.env.example`). `SQLITE_PATH` is read from `.env.local`.

```bash
npm run sync:prod
```

Run migrations against production first if the schema changed:

```bash
npm run sync:prod -- --migrate
```

Start the dev server:

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Delete the database

**Stop the container** (data is kept in the Docker volume and will be there when you start again):

```bash
docker compose down
```

**Stop and remove all data** (wipes the database — use this for a clean slate):

```bash
docker compose down -v
```

The `-v` flag removes the `pgdata` volume defined in `docker-compose.yml`. After that, run `docker compose up -d` and `npm run db:migrate` again to recreate an empty database.

To remove only the volume without using compose:

```bash
docker volume rm web_pgdata
```

(The volume name is prefixed with the compose project directory name — run `docker volume ls` if yours differs.)
