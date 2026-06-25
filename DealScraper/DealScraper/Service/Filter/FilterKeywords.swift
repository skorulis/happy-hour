//Created by Alex Skorulis on 19/6/2026.

import Foundation

nonisolated enum FilterKeywords {
    static let dealKeywords = [
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
        "covid",
        "easter",
        "events package",
        "fathersday",
        "fifa",
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
        "new years",
        "new years",
        "new-years",
        "parties",
        "this week",
        "this-week",
        "state of origin",
        "state-of-origin",
        "seinfeld",
        "simpsons",
        "stpatricks",
        "superbowl",
        "takeover",
        "theashes",
        "thepassloyaltyapp",
        "tonight",
        "tournament",
        "ufc",
        "valentines",
        "vivid",
        "xmas",
        "/post",
        "/blog",
    ]
    
    static func containsDealKeyword(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        return dealKeywords.contains { lowercased.contains($0) }
    }
    
    static func containsExcludedKeyword(_ text: String) -> Bool {
        let lowercased = text.lowercased().replacingOccurrences(of: "-", with: "")
        return excludedKeywords.contains { lowercased.contains($0) }
    }
}
