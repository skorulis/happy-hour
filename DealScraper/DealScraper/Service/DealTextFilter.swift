//Created by Alex Skorulis on 16/6/2026.

import Foundation

struct DealTextFilter {

    private static let headlinePatterns = [
        #"\bhappy hour\b"#,
        #"\bspecials\b"#,
        #"\bpromotions?\b"#,
        #"\bdeals?\b"#,
    ]
    
    private static let excludedKeywords = [
        "tonight",
        "mothers day",
        "mother's day",
        "this week",
        "state of origin",
        "new years eve",
        "new years",
        "christmas in july",
        "christmas",
    ]

    func isValidDeal(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        if Self.containsExcludedKeyword(in: trimmed) {
            return false
        }

        if Self.containsDate(in: trimmed) {
            return false
        }

        if DealDay.isMentioned(in: trimmed) {
            return true
        }

        if Self.hasDealTime(in: trimmed) {
            return true
        }

        return Self.containsHeadlineKeyword(in: trimmed)
    }

    static func containsDate(in text: String) -> Bool {
        let range = NSRange(text.startIndex..., in: text)
        return datePatterns.contains { pattern in
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
            return regex.firstMatch(in: text, range: range) != nil
        }
    }

    private static let monthPattern =
        #"(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|july?|aug(?:ust)?|sep(?:t(?:ember)?)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)"#

    private static let datePatterns = [
        #"(?i)\b"# + monthPattern + #"(?:\.?\s+\d{1,2}(?:st|nd|rd|th)?(?:,\s*\d{4})?|\s+\d{1,2}(?:st|nd|rd|th)?(?:,\s*\d{4})?)\b"#,
        #"(?i)\b\d{1,2}(?:st|nd|rd|th)?(?:\s+of)?\s+"# + monthPattern + #"(?:\.?\s+\d{4})?\b"#,
        #"(?i)\b\d{4}[-/.]\d{1,2}[-/.]\d{1,2}\b"#,
        #"(?i)\b\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4}\b"#,
    ]

    private static func containsExcludedKeyword(in text: String) -> Bool {
        let lowercased = text.lowercased()
        return excludedKeywords.contains { lowercased.contains($0) }
    }

    private static func containsHeadlineKeyword(in text: String) -> Bool {
        let range = NSRange(text.startIndex..., in: text)
        return headlinePatterns.contains { pattern in
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                return false
            }
            return regex.firstMatch(in: text, range: range) != nil
        }
    }

    private static func hasDealTime(in text: String) -> Bool {
        if DealHours.parse(text) != nil || DealHours.fromString(text) != nil {
            return true
        }

        let patterns = [
            #"(?i)(?<!\d)(\d{1,2}(?:[:.]\d{2})?\s*(?:am|pm))(?!\d)"#,
            #"(?i)\bfrom\s+\d{1,2}[:.]\d{2}\b"#,
        ]

        let range = NSRange(text.startIndex..., in: text)
        return patterns.contains { pattern in
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
            return regex.firstMatch(in: text, range: range) != nil
        }
    }
}
