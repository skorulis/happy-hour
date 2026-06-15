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

        var found = Set<DealDay>()

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
}
