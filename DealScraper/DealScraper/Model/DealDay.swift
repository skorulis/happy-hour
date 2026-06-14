//Created by Alexander Skorulis on 14/6/2026.

import Foundation

/// Describes the days a deal is valid
nonisolated enum DealDay: String, CaseIterable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday

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
}
