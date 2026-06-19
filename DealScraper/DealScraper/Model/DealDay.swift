//Created by Alexander Skorulis on 14/6/2026.

import Foundation

/// Describes the days a deal is valid
nonisolated enum DealDay: String, CaseIterable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday, everyDay

    private static let abbreviations: [String: DealDay] = [
        "mon": .monday,
        "tue": .tuesday,
        "tues": .tuesday,
        "wed": .wednesday,
        "thu": .thursday,
        "thur": .thursday,
        "thurs": .thursday,
        "fri": .friday,
        "sat": .saturday,
        "sun": .sunday,
        "every Day": .everyDay,
    ]

    private static let weekdayOrder: [DealDay] = [
        .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday,
    ]

    private static let dayTokens: [String] = {
        var tokens = Set(weekdayOrder.map(\.rawValue))
        for (abbrev, day) in abbreviations where day != .everyDay {
            tokens.insert(abbrev)
        }
        return tokens.sorted { $0.count > $1.count }
    }()

    private static let dayRangeRegex: NSRegularExpression? = {
        let tokenPattern = dayTokens
            .map { NSRegularExpression.escapedPattern(for: $0) }
            .joined(separator: "|")
        let pattern = #"\b(\#(tokenPattern))\s*(?:-|–|to)\s*(\#(tokenPattern))\b"#
        return try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    }()

    static func parse(_ string: String) -> DealDay? {
        let normalized = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalized.isEmpty else { return nil }

        if let day = DealDay(rawValue: normalized) {
            return day
        }
        return abbreviations[normalized]
    }

    static func parseAll(in string: String) -> [DealDay] {
        if let day = parse(string) {
            return [day]
        }

        let normalized = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalized.isEmpty else { return [] }

        if normalized.contains("every day")
            || normalized.replacingOccurrences(of: " ", with: "") == "everyday"
        {
            return [.everyDay]
        }

        var found = Set<DealDay>()

        if normalized.range(of: #"\bweekends?\b"#, options: .regularExpression) != nil {
            found.insert(.saturday)
            found.insert(.sunday)
        }

        parseDayRanges(in: normalized, into: &found)

        for day in DealDay.allCases where normalized.contains(day.rawValue) {
            found.insert(day)
        }

        let abbreviationsByLength = abbreviations.sorted { $0.key.count > $1.key.count }
        for (abbrev, day) in abbreviationsByLength {
            let pattern = #"\b"# + NSRegularExpression.escapedPattern(for: abbrev) + #"\b"#
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  regex.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)) != nil
            else {
                continue
            }
            found.insert(day)
        }

        return DealDay.allCases.filter { found.contains($0) }
    }

    static func isMentioned(in string: String) -> Bool {
        !parseAll(in: string).isEmpty
    }

    private static func parseDayRanges(in normalized: String, into found: inout Set<DealDay>) {
        guard let regex = dayRangeRegex else { return }
        let range = NSRange(normalized.startIndex..., in: normalized)
        regex.enumerateMatches(in: normalized, range: range) { match, _, _ in
            guard let match,
                  match.numberOfRanges >= 3,
                  let startRange = Range(match.range(at: 1), in: normalized),
                  let endRange = Range(match.range(at: 2), in: normalized),
                  let startDay = parse(String(normalized[startRange])),
                  let endDay = parse(String(normalized[endRange])),
                  startDay != .everyDay,
                  endDay != .everyDay
            else { return }

            for day in expandRange(from: startDay, to: endDay) {
                found.insert(day)
            }
        }
    }

    private static func expandRange(from start: DealDay, to end: DealDay) -> [DealDay] {
        guard let startIndex = weekdayOrder.firstIndex(of: start),
              let endIndex = weekdayOrder.firstIndex(of: end)
        else {
            return [start, end]
        }

        if startIndex <= endIndex {
            return Array(weekdayOrder[startIndex...endIndex])
        }
        return Array(weekdayOrder[startIndex...]) + Array(weekdayOrder[...endIndex])
    }

    var calendarWeekday: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        case .everyDay: return 1
        }
    }

    var scheduleDays: [DealDay] {
        switch self {
        case .everyDay:
            return [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        default:
            return [self]
        }
    }
}
