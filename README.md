# Happy Hour

Happy Hour is a project for finding and organizing bar and pub deals. The Swift code in this repository is **DealScraper** — a desktop app that crawls venue websites and extracts structured deal information (happy hours, specials, steak nights, and similar promotions).

## What DealScraper does

Bars and pubs often publish their deals across scattered pages, PDF menus, and images. DealScraper automates the work of collecting that material and turning it into structured data you can review and store.

```
happy-hour/
  DealScraper/          # macOS app source (SwiftUI)
  web/                  # Next.js website + Postgres sync
```

Key areas of the codebase:

| Area | Purpose |
|------|---------|
| `Service/Crawl/` | Website crawling, link discovery, PDF/image handling |
| `Service/` | Deal extraction, text filtering, persistence mapping |
| `Store/` | SQLite persistence for venues, sources, and deals |
| `Scene/` | SwiftUI views and view models |

## Requirements

- macOS with Xcode
- API keys (configured in the app’s Settings tab):
  - **Google Places** — for venue import
  - **OpenRouter** — for LLM-based deal extraction
  - **Markdowner** — for web page to markdown conversion

## Getting started

1. Open `DealScraper/DealScraper.xcodeproj` in Xcode.
2. Build and run the **DealScraper** scheme.
3. Enter your API keys in **Settings**.
4. Import a venue, queue a crawl, approve discovered sources, then run deal extraction.

## Running tests

In Xcode, select the **DealScraperTests** scheme and run tests (`⌘U`), or use:

```bash
xcodebuild test -project DealScraper/DealScraper.xcodeproj -scheme DealScraper
```

## Website

The `web/` directory is a Next.js app that reads from PostgreSQL. DealScraper remains the import and approval tool; approved deals are copied from its local SQLite database into Postgres for public search.

Releases deploy via GitHub Actions on `release/*` tags (build to GHCR, then SSH pull/restart). See [`web/README.md`](web/README.md).

### Prerequisites

- Node.js 20+
- Docker (for local PostgreSQL)

### Setup

1. Start Postgres:

```bash
cd web
docker compose up -d
```

Postgres listens on **port 5433** locally (not 5432) to avoid conflicting with other Docker Postgres instances. Ensure `DATABASE_URL` in `.env.local` uses `localhost:5433`.

2. Copy environment config and set your SQLite path:

```bash
cp .env.example .env.local
```

Edit `.env.local` and set `SQLITE_PATH` to your DealScraper database. When running the sandboxed macOS app, the path is typically:

```text
~/Library/Containers/com.skorulis.DealScraper/Data/Documents/db.sqlite
```

3. Install dependencies and apply migrations:

```bash
npm install
npm run db:migrate
```

4. Sync approved deals from SQLite (local Postgres):

```bash
npm run sync
```

You can also pass a path explicitly:

```bash
npm run sync -- --sqlite-path ~/Library/Containers/com.skorulis.DealScraper/Data/Documents/db.sqlite
```

To sync to **production** (duskroute.com), open an SSH tunnel to the droplet and use `npm run sync:prod` — see [web/README.md](web/README.md#sync-production).

5. Start the website:

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

### Data flow

1. Import venues, crawl websites, approve sources, and extract deals in **DealScraper**.
2. Approve deals you want to publish.
3. Run `npm run sync` in `web/` to copy non-broken venues in live regions (and their approved deals) into PostgreSQL.
4. The website serves search results from PostgreSQL only.

The sync script upserts suburbs by `(name, postcode)`, venues by `google_map_id`, and deals by `(venue_id, source_deal_id)`. It does not copy `deal_source` workflow data.

#### SQLite to PostgreSQL ID linkage

| SQLite (DealScraper) | PostgreSQL (website) | Notes |
|----------------------|----------------------|-------|
| `suburb.name` + `suburb.postcode` | `suburb.name` + `suburb.postcode` | Upserted; Postgres `suburb.id` is stable after first sync |
| `venue.google_map_id` | `venue.google_map_id` | Upserted; Postgres `venue.id` is stable after first sync |
| `deal.id` | `deal.source_deal_id` | Upserted per venue; Postgres `deal.id` is stable across syncs |
| — | `localStorage` favourites | Store Postgres `deal.id`; stable once deal sync is non-destructive |

Deals that are unapproved, expired, or removed in DealScraper are deleted from PostgreSQL on the next sync. Schedules are replaced per deal without changing the parent `deal.id`.

### API endpoints

| Endpoint | Purpose |
|----------|---------|
| `GET /api/venues?q=&limit=` | Venue autocomplete |
| `GET /api/deals?venueId=&day=&q=&activeNow=` | Deal search |
| `GET /api/venues/[id]` | Venue detail with deals |
