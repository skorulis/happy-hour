# Happy Hour Web

Next.js website that serves deal search results from PostgreSQL. Approved deals are synced from the DealScraper SQLite database — see the [root README](../README.md) for the full data flow.

Production runs on a DigitalOcean Sydney droplet at [https://duskroute.com](https://duskroute.com).

## Prerequisites

- Node.js 20+
- Docker (for local PostgreSQL and production compose)

## Database setup (local)

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

## Running the app (local)

Sync approved deals from DealScraper (set `SQLITE_PATH` in `.env.local` first):

```bash
npm run sync
```

Start the dev server:

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Deploy (DigitalOcean + Cloudflare)

Stack: Docker Compose with **Postgres 16**, **Next.js** (`output: "standalone"`), and **Caddy** (HTTPS) for `duskroute.com` / `www.duskroute.com`. Postgres is bound to `127.0.0.1` on the host only (not the public internet).

### 1. Droplet

1. Create an Ubuntu LTS droplet in **Sydney (`syd1`)**.
2. Open firewall ports **22**, **80**, and **443** only.
3. Install Docker Engine and the Compose plugin.
4. Clone this repo (e.g. to `/opt/happy-hour`).

### 2. Cloudflare DNS

For `duskroute.com` and `www`:

1. Create **A** (and **AAAA** if you have IPv6) records pointing at the droplet IP.
2. Set proxy status to **DNS only** (grey cloud) so Caddy can obtain Let's Encrypt certificates via HTTP-01.
3. After HTTPS works, you can enable the orange cloud with SSL/TLS mode **Full (strict)** if you want Cloudflare proxying.

### 3. Server env and first boot

On the droplet, from `web/`:

```bash
cp .env.production.example .env.production
# Edit .env.production: POSTGRES_PASSWORD, BETTER_AUTH_SECRET, OAuth, Maps keys
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

Or manually:

```bash
docker compose -f docker-compose.prod.yml --env-file .env.production up -d --build
docker compose -f docker-compose.prod.yml --env-file .env.production --profile migrate run --rm migrate
```

The database starts empty. Migrate creates the schema; deal data is loaded with `sync:prod` (below).

### 4. Google OAuth

Add this authorized redirect URI in Google Cloud Console:

```text
https://duskroute.com/api/auth/callback/google
```

Set `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` in `.env.production`, then redeploy.

### 5. Redeploy

```bash
cd /opt/happy-hour/web
./scripts/deploy.sh
```

From your laptop (optional):

```bash
ssh user@DROPLET_IP 'cd /opt/happy-hour/web && ./scripts/deploy.sh'
```

Rebuild is required after changing any `NEXT_PUBLIC_*` value (they are baked into the image at build time).

## Sync production

Production Postgres is **not** open to the public internet. Sync from your laptop through an SSH tunnel.

1. Open a tunnel (keep this terminal open):

```bash
ssh -L 5433:127.0.0.1:5432 user@DROPLET_IP
```

2. Create `web/.env.production.local` with the same Postgres credentials as the droplet `.env.production`:

```text
DATABASE_URL=postgresql://happyhour:YOUR_PASSWORD@localhost:5433/happyhour
```

`SQLITE_PATH` continues to come from `.env.local`.

3. Migrate (first time or after schema changes) and sync:

```bash
cd web
npm run sync:prod -- --migrate
# Later syncs:
npm run sync:prod
```

`--migrate` runs `drizzle-kit migrate` against the tunneled production URL, then syncs approved DealScraper deals. Omit `--migrate` when the schema is already up to date.

## Delete the local database

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
