//Created by Alex Skorulis on 7/7/2026.

import Foundation

nonisolated enum PromotionDateParser {

    static func parse(_ promotionDates: [String]?) -> (start: Date?, end: Date?) {
        guard let promotionDates, !promotionDates.isEmpty else {
            return (nil, nil)
        }

        var earliestStart: Date?
        var latestEnd: Date?

        for raw in promotionDates {
            let set = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "."))
            let trimmed = raw.trimmingCharacters(in: set)
            guard !trimmed.isEmpty else { continue }

            let parsed = parseLine(trimmed)
            print("EXTRACT: promotionDates: '\(trimmed)' = \(parsed)")
            if let start = parsed.start {
                earliestStart = minDate(earliestStart, start)
            }
            if let end = parsed.end {
                latestEnd = maxDate(latestEnd, end)
            }
        }

        return (earliestStart, latestEnd)
    }

    private static func parseLine(_ text: String) -> (start: Date?, end: Date?) {
        let lower = text.lowercased()

        if let fromThroughRange = parseFromThroughEndOfMonth(text) {
            return fromThroughRange
        }

        if lower.hasPrefix("until ") {
            let remainder = String(text.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
            let end = parseDate(remainder, referenceYear: nil)
            return (nil, end)
        }

        if lower.hasPrefix("from ") {
            let remainder = String(text.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
            let start = parseDate(remainder, referenceYear: nil)
            return (start, nil)
        }

        if let rangeParts = splitRange(text) {
            let endYear = year(from: rangeParts.end)
            let startYear = year(from: rangeParts.start) ?? endYear
            let start = parseDate(rangeParts.start, referenceYear: startYear)
            let end = parseDate(rangeParts.end, referenceYear: endYear ?? startYear)
            return (start, end)
        }

        if let date = parseDate(text, referenceYear: nil) {
            return (date, date)
        }

        return (nil, nil)
    }

    private static func parseFromThroughEndOfMonth(_ text: String) -> (start: Date?, end: Date?)? {
        let pattern = #"(?i)^from\s+(.+?)\s+through\s+to\s+the\s+end\s+of\s+([a-z]+)(?:\s+(\d{4}))?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let startRange = Range(match.range(at: 1), in: text),
              let monthRange = Range(match.range(at: 2), in: text)
        else {
            return nil
        }

        let startText = String(text[startRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        let monthText = String(text[monthRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        let explicitYear: Int? = {
            guard match.range(at: 3).location != NSNotFound,
                  let yearRange = Range(match.range(at: 3), in: text)
            else {
                return nil
            }
            return Int(text[yearRange])
        }()

        let start = parseDate(startText, referenceYear: explicitYear)
        let inferredYear = explicitYear
            ?? start.map { Calendar.current.component(.year, from: $0) }
            ?? Calendar.current.component(.year, from: Date())
        let end = endOfMonth(monthText, year: inferredYear)

        guard start != nil || end != nil else { return nil }
        return (start, end)
    }

    private static func splitRange(_ text: String) -> (start: String, end: String)? {
        let separators = [" – ", " — ", " - ", " to "]
        for separator in separators {
            let parts = text.components(separatedBy: separator)
            if parts.count == 2 {
                let start = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let end = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                guard !start.isEmpty, !end.isEmpty else { continue }
                return (start, end)
            }
        }
        return nil
    }

    private static func year(from text: String) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: #"\b(19|20)\d{2}\b"#) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let matchRange = Range(match.range, in: text)
        else {
            return nil
        }
        return Int(text[matchRange])
    }

    private static func parseDate(_ text: String, referenceYear: Int?) -> Date? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let withoutWeekday = stripWeekdayPrefix(from: trimmed)
        let year = year(from: withoutWeekday) ?? referenceYear ?? Calendar.current.component(.year, from: Date())

        let formatsWithYear = [
            "EEEE, d MMMM yyyy",
            "EEEE d MMMM yyyy",
            "d MMMM yyyy",
            "MMMM d, yyyy",
            "MMMM d yyyy",
        ]
        let formatsWithoutYear = [
            "EEEE, d MMMM",
            "EEEE d MMMM",
            "d MMMM",
            "MMMM d",
        ]

        for format in formatsWithYear {
            if let date = parse(withFormat: format, text: withoutWeekday, locale: .autoupdatingCurrent) {
                return startOfDay(date)
            }
        }

        for format in formatsWithoutYear {
            if var components = dateComponents(withFormat: format, text: withoutWeekday, locale: .autoupdatingCurrent) {
                components.year = year
                if let date = Calendar.current.date(from: components) {
                    return startOfDay(date)
                }
            }
        }

        return nil
    }

    private static func stripWeekdayPrefix(from text: String) -> String {
        let pattern = #"^(?i)(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday),?\s+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
    }

    private static func parse(withFormat format: String, text: String, locale: Locale) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Calendar.current
        formatter.dateFormat = format
        return formatter.date(from: text)
    }

    private static func endOfMonth(_ monthText: String, year: Int) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = Calendar.current
        formatter.dateFormat = "LLLL"
        guard let monthDate = formatter.date(from: monthText.capitalized) else { return nil }

        let month = Calendar.current.component(.month, from: monthDate)
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        guard let firstOfMonth = Calendar.current.date(from: components),
              let endOfMonth = Calendar.current.date(
                  byAdding: DateComponents(month: 1, day: -1),
                  to: firstOfMonth
              )
        else {
            return nil
        }
        return startOfDay(endOfMonth)
    }

    private static func dateComponents(
        withFormat format: String,
        text: String,
        locale: Locale
    ) -> DateComponents? {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Calendar.current
        formatter.dateFormat = format
        guard let date = formatter.date(from: text) else { return nil }
        return Calendar.current.dateComponents([.day, .month], from: date)
    }

    private static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private static func minDate(_ lhs: Date?, _ rhs: Date) -> Date {
        guard let lhs else { return rhs }
        return min(lhs, rhs)
    }

    private static func maxDate(_ lhs: Date?, _ rhs: Date) -> Date {
        guard let lhs else { return rhs }
        return max(lhs, rhs)
    }
}
