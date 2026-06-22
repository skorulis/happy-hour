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

4. Sync approved deals from SQLite:

```bash
npm run sync
```

You can also pass a path explicitly:

```bash
npm run sync -- --sqlite-path ~/Library/Containers/com.skorulis.DealScraper/Data/Documents/db.sqlite
```

5. Start the website:

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

### Data flow

1. Import venues, crawl websites, approve sources, and extract deals in **DealScraper**.
2. Approve deals you want to publish.
3. Run `npm run sync` in `web/` to copy venues with approved deals into PostgreSQL.
4. The website serves search results from PostgreSQL only.

The sync script upserts venues by `google_map_id`, replaces deals per venue, and does not copy `deal_source` workflow data.

### API endpoints

| Endpoint | Purpose |
|----------|---------|
| `GET /api/venues?q=&limit=` | Venue autocomplete |
| `GET /api/deals?venueId=&day=&q=&activeNow=` | Deal search |
| `GET /api/venues/[id]` | Venue detail with deals |
