# Happy Hour

Happy Hour is a project for finding and organizing bar and pub deals. The Swift code in this repository is **DealScraper** — a desktop app that crawls venue websites and extracts structured deal information (happy hours, specials, steak nights, and similar promotions).

## What DealScraper does

Bars and pubs often publish their deals across scattered pages, PDF menus, and images. DealScraper automates the work of collecting that material and turning it into structured data you can review and store.

```
DealScraper/
  DealScraper/          # macOS app source (SwiftUI)
  DealScraperTests/     # Unit tests
  DealScraper.xcodeproj # Xcode project
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
