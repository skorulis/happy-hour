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
    
    static let productKeywords: [String] = [
        // drinks
        "beer",
        "cocktails",
        "drinks",
        "guinness",
        "jug",
        "marg",
        "martini",
        "negroni",
        "pints",
        "porter",
        "rose",
        "spritz",
        "wine",
        
        // Food
        "burger",
        "chicken",
        "curry",
        "gyros",
        "meal",
        "pasta",
        "pizza",
        "porterhouse",
        "roast",
        "rump",
        "parma",
        "parmi",
        "parmy",
        "ribs",
        "salad",
        "sandwich",
        "schnitzel",
        "schnitty",
        "sirloin",
        "steak",
        "taco",
        "wings",
        
        // Events
        "brunch",
        "lunch",
        "dinner",
        "night",
        "trivia",
        "bottomless",
        
        // Other
        "bingo",
        "comedy",
        "pool",
        "meat tray",
        "2-4-1",
        "2 for 1",
        "karaoke",
        "jazz",
    ]
    
    static let excludedKeywords = [
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
