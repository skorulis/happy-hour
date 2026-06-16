//Created by Alex Skorulis on 16/6/2026.

import Foundation

struct DealTextFilter {

    private static let headlinePatterns = [
        #"\bhappy hour\b"#,
        #"\bspecials\b"#,
        #"\bpromotions?\b"#,
        #"\bdeals?\b"#,
    ]

    func isValidDeal(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        if DealDay.isMentioned(in: trimmed) {
            return true
        }

        if Self.hasDealTime(in: trimmed) {
            return true
        }

        return Self.containsHeadlineKeyword(in: trimmed)
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
            #"(?i)(?<!\d)(\d{1,2}(?::\d{2})?\s*(?:am|pm))(?!\d)"#,
            #"(?i)\bfrom\s+\d{1,2}:\d{2}\b"#,
        ]

        let range = NSRange(text.startIndex..., in: text)
        return patterns.contains { pattern in
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
            return regex.firstMatch(in: text, range: range) != nil
        }
    }
}
