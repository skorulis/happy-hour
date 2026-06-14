//Created by Alexander Skorulis on 14/6/2026.

import Foundation

/// Describes the hours a deal is valid. Integer values represent minutes from midnight. 9AM = 540
nonisolated enum DealHours: Equatable, Hashable {
    case from(Int)
    case between(Int, Int)
    case allDay

    private static let minMinutes = 420  // 7 AM
    private static let maxMinutes = 1260 // 9 PM

    static func toMinutes(string: String) -> Int? {
        let normalized = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalized.isEmpty else { return nil }

        let pattern = #"^(\d{1,2})(?::(\d{2}))?\s*(am|pm)?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                  in: normalized,
                  range: NSRange(normalized.startIndex..., in: normalized)
              ),
              let hourRange = Range(match.range(at: 1), in: normalized),
              let hour = Int(normalized[hourRange]),
              hour >= 1, hour <= 12
        else {
            return nil
        }

        let minute: Int
        if match.range(at: 2).location != NSNotFound {
            guard let minuteRange = Range(match.range(at: 2), in: normalized),
                  let parsedMinute = Int(normalized[minuteRange]),
                  parsedMinute >= 0, parsedMinute < 60
            else {
                return nil
            }
            minute = parsedMinute
        } else {
            minute = 0
        }

        if match.range(at: 3).location != NSNotFound,
           let periodRange = Range(match.range(at: 3), in: normalized) {
            let isPM = normalized[periodRange] == "pm"
            return minutesFrom(hour: hour, minute: minute, isPM: isPM)
        }

        let amMinutes = minutesFrom(hour: hour, minute: minute, isPM: false)
        let pmMinutes = minutesFrom(hour: hour, minute: minute, isPM: true)

        let inRange = [amMinutes, pmMinutes].filter { $0 >= minMinutes && $0 <= maxMinutes }
        switch inRange.count {
        case 1:
            return inRange[0]
        case 2:
            return pmMinutes
        default:
            return nil
        }
    }

    private static func minutesFrom(hour: Int, minute: Int, isPM: Bool) -> Int {
        var adjustedHour = hour % 12
        if isPM {
            adjustedHour += 12
        }
        return adjustedHour * 60 + minute
    }

    static func fromString(_ string: String) -> DealHours? {
        let normalized = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "–", with: "-")
        guard !normalized.isEmpty else { return nil }

        var timePart = normalized
        if normalized.lowercased().hasPrefix("from ") {
            timePart = String(normalized.dropFirst(5))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard !timePart.isEmpty else { return nil }

        return parse(timePart)
    }

    static func parse(_ string: String) -> DealHours? {
        let normalized = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "–", with: "-")
        guard !normalized.isEmpty else { return nil }

        if normalized == "all day" || normalized == "all-day" || normalized == "allday" {
            return .allDay
        }

        let rangeSeparators = [" - ", "-", " to "]
        for separator in rangeSeparators {
            let parts = normalized.components(separatedBy: separator)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if parts.count == 2,
               let start = toMinutes(string: parts[0]),
               let end = toMinutes(string: parts[1]) {
                return .between(start, end)
            }
        }

        guard let minutes = toMinutes(string: normalized) else { return nil }
        return .from(minutes)
    }
}
