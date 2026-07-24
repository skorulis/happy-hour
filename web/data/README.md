# Product keywords

Shared keyword list used for search suggestions and query expansion. Defined in [`products.json`](products.json).

## Entry fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | yes | Keyword label shown in suggestions and chips. |
| `rank` | no | Lower number = higher priority for **initial** suggestions when the What field is focused with no typed text (e.g. `happy hour` → 1, `drinks` → 2, `food` → 3). |
| `groups` | no | Other keyword `name` values implicitly included when this keyword is used in search. For example, selecting `beer` also matches deals mentioning `schooner`, `pint`, or `jugs`. Group expansion happens at search time only — child keywords are not shown as extra chips. |
| `synonyms` | no | Alternate substrings that map to this product when matching deal title/details text (e.g. `cocktail` → `cocktails`). Unlike `groups`, synonyms are not separate catalog keywords and are not used for search-group expansion. |
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
