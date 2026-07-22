# Product keywords

Shared keyword list used for search suggestions and query expansion. Defined in [`products.json`](products.json).

## Region map boundaries

The `/regions` page renders an SVG map from committed TopoJSON files:

| File | Purpose |
|------|---------|
| [`region-boundaries.json`](region-boundaries.json) | Maps product region slugs to ABS ASGS boundary layers |
| [`regions-australia.json`](regions-australia.json) | Clickable region polygons |
| [`australia-outline.json`](australia-outline.json) | Muted Australia state background |

### Refreshing boundaries

When adding a region:

1. Add an entry to `region-boundaries.json` (`absLayer`: `GCCSA` or `LGA`, `absName`: exact ABS feature name).
2. Regenerate TopoJSON:

```bash
# Remote fetch from geo.abs.gov.au (no local ABS download required)
npm run build:region-boundaries -- --fetch

# Or from local ABS GeoJSON files
ASGS_BOUNDARIES_PATH=~/Downloads/asgs-boundaries/2021/GeoJSON npm run build:region-boundaries
```

Local ASGS GeoJSON can be downloaded from [ABS ASGS Edition 3 digital boundary files](https://www.abs.gov.au/statistics/standards/australian-statistical-geography-standard-asgs-edition-3/jul2021-jun2026/access-and-downloads/digital-boundary-files).

Commit the updated `.json` boundary files with your region change.

## Entry fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | yes | Keyword label shown in suggestions and chips. |
| `rank` | no | Lower number = higher priority for **initial** suggestions when the What field is focused with no typed text (e.g. `happy hour` → 1, `drinks` → 2, `food` → 3). |
| `groups` | no | Other keyword `name` values implicitly included when this keyword is used in search. For example, selecting `beer` also matches deals mentioning `schooner`, `pint`, or `jugs`. Group expansion happens at search time only — child keywords are not shown as extra chips. |
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
