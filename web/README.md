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

Production releases use the same pattern as maxidle: push a `release/*` tag → GitHub Actions builds images to GHCR → SSH to the droplet → pull and restart.

### Deploy a release

```bash
git tag release/0.1.0
git push origin release/0.1.0
```

Watch **Actions → Deploy production**. After it succeeds, check [https://duskroute.com](https://duskroute.com).

Rollback on the droplet:

```bash
export IMAGE_TAG=release-0.1.0
export WEB_IMAGE_REPO=ghcr.io/skorulis/happy-hour-web
export MIGRATE_IMAGE_REPO=ghcr.io/skorulis/happy-hour-migrate
/opt/happy-hour/deploy/scripts/deploy-release.sh
```

### GitHub Actions secrets

| Secret | Example / notes |
|--------|-----------------|
| `PROD_WEB_IMAGE_REPO` | `ghcr.io/skorulis/happy-hour-web` |
| `PROD_MIGRATE_IMAGE_REPO` | `ghcr.io/skorulis/happy-hour-migrate` |
| `PROD_NEXT_PUBLIC_SITE_URL` | `https://duskroute.com` (baked into the image) |
| `PROD_NEXT_PUBLIC_GOOGLE_MAPS_API_KEY` | Maps JS key |
| `PROD_NEXT_PUBLIC_GOOGLE_MAPS_MAP_ID` | Map ID |
| `PROD_SERVER_HOST` | `134.199.156.128` |
| `PROD_SERVER_USER` | `root` (or a deploy user in the `docker` group) |
| `PROD_SERVER_SSH_KEY` | Private key PEM that can SSH to the droplet |
| `PROD_GHCR_USERNAME` | GitHub username (for private package pulls on the server) |
| `PROD_GHCR_TOKEN` | PAT with `read:packages` (or a fine-grained token that can read GHCR) |

Server-side secrets (DB password, auth, OAuth) stay in `/opt/happy-hour/deploy/.env.production` — not in GitHub.

### One-time droplet bootstrap

On a fresh Ubuntu droplet (Sydney / `syd1`):

```bash
git clone git@github.com:skorulis/happy-hour.git /opt/happy-hour
# or: git clone https://github.com/skorulis/happy-hour.git /opt/happy-hour
cd /opt/happy-hour
sudo ./deploy/scripts/bootstrap-vps.sh
```

That installs Docker + Compose, opens UFW for 22/80/443, copies deploy files to `/opt/happy-hour/deploy`, and creates `.env.production` with generated `POSTGRES_PASSWORD` / `BETTER_AUTH_SECRET`.

Then:

1. Edit `/opt/happy-hour/deploy/.env.production` for OAuth / Maps keys if needed.
2. Cloudflare DNS: `duskroute.com` + `www` A records → droplet IP (`134.199.156.128`), **DNS only** until Caddy has a cert; then orange-cloud + **Full (strict)** is fine.
3. Set GitHub Actions secrets (`PROD_SERVER_HOST=134.199.156.128`, SSH key, image repos, Maps, GHCR pull token — see table above).
4. From your laptop: `git tag release/0.1.0 && git push origin release/0.1.0`

If you already ran `web/docker-compose.prod.yml` on an *old* droplet and have data in volume `web_pgdata`, copy it before the first CI deploy:

```bash
docker volume create duskroute_pgdata
docker run --rm -v web_pgdata:/from -v duskroute_pgdata:/to alpine \
  sh -c 'cd /from && cp -a . /to'
```

(Skip that on a brand-new empty droplet.)

### Google OAuth

Authorized redirect URI:

```text
https://duskroute.com/api/auth/callback/google
```

Set `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` in `/opt/happy-hour/deploy/.env.production`, then redeploy (new tag or re-run the workflow).

### Emergency on-server rebuild

If CI/GHCR is unavailable, you can still build on the droplet with `web/scripts/deploy.sh` and `web/docker-compose.prod.yml` (slow on a small VPS). Prefer tag deploys for normal releases.

Changing any `NEXT_PUBLIC_*` value requires a new image build (update the GitHub secret, then push a new `release/*` tag).

## Sync production

Production Postgres is **not** open to the public internet. Sync from your laptop through an SSH tunnel.

1. Open a tunnel (keep this terminal open):

```bash
ssh -L 5433:127.0.0.1:5432 user@DROPLET_IP
```

2. Create `web/.env.production.local` with the same Postgres credentials as the droplet `/opt/happy-hour/deploy/.env.production`:

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
