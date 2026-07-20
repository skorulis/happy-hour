/**
 * Ported from `DealScraper/DealScraper/Service/Filter/FilterKeywords.swift`.
 *
 * Only the excluded-keyword list and matcher are needed for deal mapping.
 */

export const excludedKeywords = [
  "404",
  "anzac",
  "birthday",
  "blackfriday",
  "catering",
  "city2surf",
  "christmas in july",
  "christmas",
  "conferences",
  "covid",
  "cricket",
  "easter",
  "eofy",
  "events package",
  "fathersday",
  "fifa",
  "financialyear",
  "footy",
  "fortnightly",
  "functions",
  "goodfriday",
  "grandfinal",
  "harrypotter",
  "kingsbirthday",
  "longweekend",
  "mardigras",
  "melbournecup",
  "mothersday",
  "mothers day",
  "mothers-day",
  "mother's day",
  "nba",
  "nrl",
  "nye",
  "newyears",
  "origin",
  "oktoberfest",
  "parties",
  "pridemonth",
  "privateevents",
  "privatedining",
  "rugby",
  "state of origin",
  "state-of-origin",
  "seinfeld",
  "simpsons",
  "soccer",
  "stpatricks",
  "stpaddys",
  "superbowl",
  "takeover",
  "theashes",
  "thepassloyaltyapp",
  "this week",
  "this-week",
  "tonight",
  "tourdefrance",
  "tournament",
  "ufc",
  "valentines",
  "vivid",
  "weddings",
  "worldcup",
  "xmas",
  "/post",
  "/blog",
];

function normalizeForKeywordMatch(text: string): string {
  return text
    .toLowerCase()
    .replace(/-/g, "")
    .replace(/'/g, "")
    .replace(/ /g, "");
}

export function containsExcludedKeyword(text: string): boolean {
  const normalized = normalizeForKeywordMatch(text);
  return excludedKeywords.some((keyword) =>
    normalized.includes(normalizeForKeywordMatch(keyword)),
  );
}
