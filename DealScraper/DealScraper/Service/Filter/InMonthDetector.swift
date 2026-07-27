//Created by Alex Skorulis on 27/7/2026.

import Foundation

/// Detects "In {month}" poster copy (e.g. "IN DECEMBER") that is outside the current or next month.
/// Stale month banners are usually leftovers from a previous year.
nonisolated enum InMonthDetector {

    private static let monthPattern =
        #"(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|july?|aug(?:ust)?|sep(?:t(?:ember)?)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)"#

    private static let pattern: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"(?i)\bin\s+(\#(monthPattern))\b"#)
    }()

    private static let monthNumberByName: [String: Int] = [
        "jan": 1, "january": 1,
        "feb": 2, "february": 2,
        "mar": 3, "march": 3,
        "apr": 4, "april": 4,
        "may": 5,
        "jun": 6, "june": 6,
        "jul": 7, "july": 7,
        "aug": 8, "august": 8,
        "sep": 9, "sept": 9, "september": 9,
        "oct": 10, "october": 10,
        "nov": 11, "november": 11,
        "dec": 12, "december": 12,
    ]

    /// True when OCR contains an "In {month}" phrase for a month other than this or next month.
    static func isMatch(in texts: [String], now: Date = .now) -> Bool {
        let allowed = allowedMonths(relativeTo: now)
        return texts.contains { text in
            months(in: text).contains { !allowed.contains($0) }
        }
    }

    static func allowedMonths(relativeTo date: Date, calendar: Calendar = .current) -> Set<Int> {
        let current = calendar.component(.month, from: date)
        let next = current == 12 ? 1 : current + 1
        return [current, next]
    }

    private static func months(in text: String) -> [Int] {
        let trimmed = OCRTextNormalizer.normalize(text)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let pattern else { return [] }

        let range = NSRange(trimmed.startIndex..., in: trimmed)
        let matches = pattern.matches(in: trimmed, range: range)
        return matches.compactMap { match -> Int? in
            guard match.numberOfRanges >= 2,
                  let monthRange = Range(match.range(at: 1), in: trimmed)
            else {
                return nil
            }
            return monthNumberByName[trimmed[monthRange].lowercased()]
        }
    }
}
