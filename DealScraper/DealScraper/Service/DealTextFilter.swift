//Created by Alex Skorulis on 16/6/2026.

import Foundation

struct DealTextFilter {

    static func isExpiredPage(_ text: String) -> Bool {
        FilterKeywords.isExpiredPage(text)
    }

    func isValidDeal(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        if Self.isExpiredPage(trimmed) {
            return false
        }

        if Self.containsExcludedKeyword(in: trimmed) {
            return false
        }

        if Self.containsDate(in: trimmed) {
            return false
        }
        
        let hasDay = DealDay.isMentioned(in: trimmed)
        let hasTime = Self.hasDealTime(in: trimmed)

        if !hasDay && !hasTime {
            return false
        }

        return Self.containsHeadlineKeyword(in: trimmed) || Self.containsPrice(in: trimmed)
    }

    static func containsPrice(in text: String) -> Bool {
        let range = NSRange(text.startIndex..., in: text)
        return pricePatterns.contains { pattern in
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
            return regex.firstMatch(in: text, range: range) != nil
        }
    }

    private static let pricePatterns = [
        #"(?i)\$\s*\d+(?:\.\d{2})?"#,
        #"(?i)\bhalf[\s-]?price\b"#,
    ]

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
        FilterKeywords.containsExcludedKeyword(text)
    }

    private static func containsHeadlineKeyword(in text: String) -> Bool {
        let lowercased = text.lowercased()
        return FilterKeywords.dealKeywords.contains { lowercased.contains($0) } ||
            FilterKeywords.productKeywords.contains { lowercased.contains($0) }
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
