//Created by Alex Skorulis on 19/6/2026.

import Foundation

nonisolated enum FilterKeywords {
    static let dealKeywords = [
        "bottomless",
        "happy hour",
        "specials",
        "what's on",
        "whats on",
        "whats-on",
        "whatson",
        "events",
        "promotions",
        "deals",
        "menu",
        "drinks",
        "food",
        "happyhour",
        "eatdrink",
        "weekly",
        "weekends",
        "weekdays",
    ]
    
    static let productKeywords: [String] = ProductsCatalog.productNames
    
    static let excludedKeywords = [
        "anzac",
        "birthday",
        "christmas in july",
        "christmas",
        "conferences",
        "covid",
        "easter",
        "eofy",
        "events package",
        "fathersday",
        "fifa",
        "financialyear",
        "footy",
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
        "newyears",
        "origin",
        "oktoberfest",
        "parties",
        "pridemonth",
        "privateevents",
        "privatedining",
        "state of origin",
        "state-of-origin",
        "seinfeld",
        "simpsons",
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
    ]
    
    static func containsDealKeyword(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        return dealKeywords.contains { lowercased.contains($0) }
    }
    
    static func containsExcludedKeyword(_ text: String) -> Bool {
        let normalized = normalizeForKeywordMatch(text)
        return excludedKeywords.contains { normalized.contains(normalizeForKeywordMatch($0)) }
    }

    private static func normalizeForKeywordMatch(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
}
