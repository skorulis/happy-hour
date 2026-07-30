# Product keywords

Shared keyword list used for search suggestions and query expansion. Defined in [`products.json`](products.json).

## Entry fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | yes | Keyword label shown in suggestions and chips. |
| `rank` | no | Lower number = higher priority for **initial** suggestions when the What field is focused with no typed text (e.g. `happy hour` → 1, `drinks` → 2, `food` → 3). |
| `groups` | no | Other keyword `name` values implicitly included when this keyword is used in search. For example, selecting `beer` also matches deals mentioning `schooner`, `pint`, or `jugs`. Group expansion happens at search time only — child keywords are not shown as extra chips. |
| `synonyms` | no | Alternate substrings that map to this product when matching deal title/details text (e.g. `cocktail` → `cocktails`). Unlike `groups`, synonyms are not separate catalog keywords and are not used for search-group expansion. |
| `match` | no | When `false`, this product is never searched during extract / map-icon text matching. Use for top-level category keywords (e.g. `drinks`, `food`, `events`) that exist for search suggestions and group expansion only. Omit or `true` to allow matching. |
| `noprice` | no | When `true`, extract never associates a `$` amount with this product (price is always `null`). Use for non-priced promotions such as `raffle` and `meat tray`. |
| `icon` | no | Registered icon name (PascalCase, e.g. `Beer`, `Pizza`) used as the map marker when deal text matches this keyword. Icons may come from Lucide, Lucide Lab, or custom icons — each name must exist in the web `ProductMapIcon` registry. Omit when no suitable icon exists. |

## Example

```json
{
  "name": "beer",
  "icon": "Beer",
  "groups": ["schooner", "pint", "jugs"]
}
```

Searching for `beer` will also match deals containing any of `schooner`, `pint`, or `jugs`. A venue whose deal text mentions `beer` shows the Beer icon on the map; venues with no matching icon keyword fall back to the standard map pin.

```json
{
  "name": "cocktails",
  "icon": "Martini",
  "synonyms": ["cocktail"]
}
```

Deal text containing `cocktail` (singular) matches the `cocktails` product during extract and map-icon matching.

```json
{
  "name": "drinks",
  "rank": 2,
  "icon": "Wine",
  "match": false,
  "groups": ["beer", "cocktails", "wine"]
}
```

`drinks` stays available as a search suggestion and expands to its groups, but deal text mentioning “drinks” does not extract or map-icon-match the `drinks` product itself.

## Match ignore phrases

Global substrings that should not count as product matches. Defined in [`match-ignore.json`](match-ignore.json).

If a product name or synonym appears only inside one of these phrases, that hit is skipped for every product. For example, `All chips down special` does not match `chips` when `chips down` is listed.

```json
[
  "chips down"
]
```

## Match rules

- **With-clause ignore:** From the word `with` through the end of that line is ignored for product matching. Those phrases describe sides or inclusions (e.g. `With house beer or wine`), not the product itself. Text before `with` still matches (e.g. `Steak with chips` → `steak`).
- **Bottomless title-only:** If the deal title matches `bottomless`, product matching uses the title only and ignores details. Other title keywords (e.g. `Bottomless pizza`) still match.

# Venue features

Catalog of venue amenities and spaces (e.g. outdoor areas) stored per venue in `venue_feature`. Defined in [`features.json`](features.json).

## Entry fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | yes | Canonical feature label stored on `venue_feature.feature` (e.g. `beer garden`, `rooftop`). |
| `synonyms` | no | Alternate substrings for future text matching (e.g. `beer gardens` → `beer garden`). |

## Example

```json
{
  "name": "beer garden",
  "synonyms": ["beer gardens"]
}
```

# Geographic regions

Approved geographic regions used by DealScraper (and shared with the web via the `data/` copy). Defined in [`regions.json`](regions.json).

## Entry fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | yes | Display name for the region (must match seeded `geographic_region.name` values). |
| `status` | yes | `"live"`, `"in-progress"`, or `"future"`. Controls web sync: `"live"` regions copy the full suburb catalog and all non-broken venues to Postgres; other statuses do not sync venues. DealScraper seeds all listed regions regardless of status. |
| `country` | yes | ISO 3166-1 alpha-3 code for the region's country (`AUS`, `NZL`, …). Must match a seeded `country.iso3` value. |

## Example

```json
{
  "name": "Sydney",
  "status": "live",
  "country": "AUS"
}
```

When syncing SQLite → Postgres, only `"live"` regions receive every suburb and every non-broken venue (including venues with no deals). Non-live region rows still sync; empty suburbs in those regions are pruned. Full syncs also prune Postgres venues that are broken or outside live regions.
