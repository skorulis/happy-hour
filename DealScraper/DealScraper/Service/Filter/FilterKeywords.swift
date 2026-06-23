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
        "eat-drink",
        "weekly",
        "weekends",
        "weekdays",
    ]
    
    static let productKeywords: [String] = [
        "wine",
        "beer",
        "jug",
        "pints",
        "marg",
        "cocktails",
        "spritz",
        "martini",
        "drinks",
        "rose",
        
        // Food
        "burger",
        "chicken",
        "curry",
        "meal",
        "pasta",
        "pizza",
        "roast",
        "rump",
        "salad",
        "sandwich",
        "schnitzel",
        "sirloin",
        "steak",
        "wings",
        
        // Events
        "brunch",
        "lunch",
        "dinner",
        "trivia",
        "bottomless",
        
        // Other
        "meat tray",
        "2-4-1",
        "2 for 1",
    ]
    
    static let excludedKeywords = [
        "functions",
        "events package",
        "covid",
        "tonight",
        "mothers day",
        "mothers-day",
        "mother's day",
        "this week",
        "this-week",
        "state of origin",
        "state-of-origin",
        "new years eve",
        "new years",
        "new-years",
        "christmas in july",
        "christmas",
        "parties"
    ]
    
    static func containsDealKeyword(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        return dealKeywords.contains { lowercased.contains($0) }
    }
    
    static func containsExcludedKeyword(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        return excludedKeywords.contains { lowercased.contains($0) }
    }
}
