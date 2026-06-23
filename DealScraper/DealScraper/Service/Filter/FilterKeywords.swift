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
        "gyros",
        "meal",
        "pasta",
        "pizza",
        "roast",
        "rump",
        "salad",
        "sandwich",
        "schnitzel",
        "schnitty",
        "sirloin",
        "steak",
        "wings",
        
        // Events
        "brunch",
        "lunch",
        "dinner",
        "night",
        "trivia",
        "bottomless",
        
        // Other
        "pool",
        "meat tray",
        "2-4-1",
        "2 for 1",
        "jazz",
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
        "new years",
        "new years",
        "new-years",
        "christmas in july",
        "christmas",
        "parties",
        "superbowl",
        "theashes",
        "grandfinal",
        "melbournecup",
        "xmas",
        "goodfriday",
        "tournament",
        "harrypotter",
        "easter",
        "mardigras",
        "seinfeld",
        "simpsons",
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
