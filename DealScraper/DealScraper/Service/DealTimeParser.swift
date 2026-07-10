//Created by Alex Skorulis on 24/6/2026.

import Foundation

nonisolated enum DealTimeParser {

    static func parse(_ strings: [String]) -> [DealHours] {
        let trimmed = strings
            .map(sanitizeTimeString)
            .filter { !$0.isEmpty }
        guard !trimmed.isEmpty else { return [] }

        if trimmed.allSatisfy({ isAllDayToken($0) }) {
            return [.allDay]
        }

        if let range = parseFromDrawnAtRange(in: trimmed) {
            return [range]
        }

        var times: [DealHours] = []
        for string in trimmed {
            if let time = parseFromDrawnRange(in: string) {
                times.append(time)
            } else if let time = parseHoursFromRange(in: string) {
                times.append(time)
            } else if let time = parseTillOrUntilTime(in: string) {
                times.append(time)
            } else if let time = parseBetweenTime(in: string) {
                times.append(time)
            } else if let time = DealHours.parse(string) {
                times.append(time)
            } else if let time = parseMultipleTimesAsRange(in: string) {
                times.append(time)
            } else {
                times.append(contentsOf: timesInText(string))
            }
        }
        return Array(Set(times))
    }

    static func timesInText(_ text: String) -> [DealHours] {
        let text = sanitizeTimeString(text)
        if let time = parseFromDrawnRange(in: text) {
            return [time]
        }
        if let time = parseHoursFromRange(in: text) {
            return [time]
        }
        if let time = parseTillOrUntilTime(in: text) {
            return [time]
        }
        if let time = parseBetweenTime(in: text) {
            return [time]
        }
        if let time = DealHours.parse(text) {
            return [time]
        }
        if let time = parseMultipleTimesAsRange(in: text) {
            return [time]
        }

        let pattern = #"(?i)(?<!\d)(\d{1,2}(?:[:.]\d{2})?\s*(?:am|pm)?)(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)

        return matches.compactMap { match in
            guard let matchRange = Range(match.range(at: 1), in: text) else { return nil }
            return DealHours.parse(String(text[matchRange]))
        }
    }

    private static func stripTimeLabelPrefix(_ string: String) -> String {
        let pattern = #"(?i)^times?\s*[-:]\s*"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
              let range = Range(match.range, in: string)
        else { return string }
        return String(string[range.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalizeDottedMeridiem(_ string: String) -> String {
        string
            .replacingOccurrences(of: #"(?i)a\.m\.?"#, with: "am", options: .regularExpression)
            .replacingOccurrences(of: #"(?i)p\.m\.?"#, with: "pm", options: .regularExpression)
    }

    /// OCR and font substitutions sometimes render "to" as "tº" or "t°".
    private static func normalizeOCRToToken(_ string: String) -> String {
        string.replacingOccurrences(
            of: #"(?i)t[º°0]"#,
            with: "to",
            options: .regularExpression
        )
    }

    private static func sanitizeTimeString(_ string: String) -> String {
        var result = string
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "\u{2018}", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        result = normalizeDottedMeridiem(result)
        result = normalizeOCRToToken(result)
        result = stripTimeLabelPrefix(result)
        result = stripListMarkers(result)
        let wrappers: [(Character, Character)] = [("(", ")"), ("[", "]"), ("*", "*"), ("_", "_")]
        var changed = true
        while changed {
            changed = false
            result = result.trimmingCharacters(in: .whitespacesAndNewlines)
            for (open, close) in wrappers {
                if result.first == open, result.last == close, result.count > 1 {
                    result = String(result.dropFirst().dropLast())
                    changed = true
                }
            }
        }
        return result
    }

    private static func stripListMarkers(_ string: String) -> String {
        let markers: [Character] = ["\u{2022}", "\u{2023}", "\u{00B7}", "\u{25E6}", "\u{2219}"]
        var result = string
        var changed = true
        while changed {
            changed = false
            result = result.trimmingCharacters(in: .whitespacesAndNewlines)
            for marker in markers {
                if result.first == marker {
                    result = String(result.dropFirst())
                    changed = true
                }
                if result.last == marker {
                    result = String(result.dropLast())
                    changed = true
                }
            }
        }
        return result
    }

    private static func isAllDayToken(_ string: String) -> Bool {
        switch string.lowercased() {
        case "all day", "all-day", "allday":
            return true
        default:
            return false
        }
    }

    private static func parseTillOrUntilTime(in text: String) -> DealHours? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let time = #"\d{1,2}(?:[:.]\d{2})?\s*(?:am|pm)?"#
        let till = #"(?:'?(?:till|til)|until)"#

        let fromTillPattern = #"(?i)from\s+(\#(time))\s+\#(till)\s+(\#(time))"#
        if let regex = try? NSRegularExpression(pattern: fromTillPattern),
           let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
           let startRange = Range(match.range(at: 1), in: trimmed),
           let endRange = Range(match.range(at: 2), in: trimmed),
           let start = DealHours.toMinutes(string: String(trimmed[startRange])),
           let end = DealHours.toMinutes(string: String(trimmed[endRange])) {
            return DealHours.makeBetween(start: start, end: end)
        }

        let tillRangePattern = #"(?i)(\#(time))\s+\#(till)\s+(\#(time))"#
        if let regex = try? NSRegularExpression(pattern: tillRangePattern),
           let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
           let startRange = Range(match.range(at: 1), in: trimmed),
           let endRange = Range(match.range(at: 2), in: trimmed),
           let start = DealHours.toMinutes(string: String(trimmed[startRange])),
           let end = DealHours.toMinutes(string: String(trimmed[endRange])) {
            return DealHours.makeBetween(start: start, end: end)
        }

        let tillOnlyPattern = #"(?i)\#(till)\s+(\#(time))"#
        if let regex = try? NSRegularExpression(pattern: tillOnlyPattern),
           let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
           let endRange = Range(match.range(at: 1), in: trimmed),
           let end = DealHours.toMinutes(string: String(trimmed[endRange])) {
            return .between(0, end)
        }

        return nil
    }

    private static func parseFromDrawnRange(in text: String) -> DealHours? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let time = #"\d{1,2}(?:[:.]\d{2})?\s*(?:am|pm)?"#
        let pattern = #"(?i)from\s+(\#(time)).*drawn(?:\s+at)?\s+(\#(time))"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
              let startRange = Range(match.range(at: 1), in: trimmed),
              let endRange = Range(match.range(at: 2), in: trimmed),
              let start = DealHours.toMinutes(string: String(trimmed[startRange])),
              let end = DealHours.toMinutes(string: String(trimmed[endRange]))
        else {
            return nil
        }

        return DealHours.makeBetween(start: start, end: end)
    }

    private static func parseFromDrawnAtRange(in strings: [String]) -> DealHours? {
        let time = #"\d{1,2}(?:[:.]\d{2})?\s*(?:am|pm)?"#
        let fromOnlyPattern = #"(?i)^from\s+(\#(time))$"#
        let drawnAtPattern = #"(?i)^drawn(?:\s+at)?\s+(\#(time))$"#

        var startMinutes: Int?
        var endMinutes: Int?

        for string in strings {
            if let regex = try? NSRegularExpression(pattern: fromOnlyPattern),
               let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
               let timeRange = Range(match.range(at: 1), in: string),
               let minutes = DealHours.toMinutes(string: String(string[timeRange])) {
                startMinutes = minutes
            } else if let regex = try? NSRegularExpression(pattern: drawnAtPattern),
                      let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
                      let timeRange = Range(match.range(at: 1), in: string),
                      let minutes = DealHours.toMinutes(string: String(string[timeRange])) {
                endMinutes = minutes
            }
        }

        guard let start = startMinutes, let end = endMinutes else { return nil }
        return DealHours.makeBetween(start: start, end: end)
    }

    private static func parseMultipleTimesAsRange(in text: String) -> DealHours? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let listPattern = #"(?i)[,&]|(?:\band\b)"#
        guard trimmed.range(of: listPattern, options: .regularExpression) != nil else {
            return nil
        }

        let timePattern = #"(?i)(?<!\d)(\d{1,2}(?:[:.]\d{2})?\s*(?:am|pm)?)(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: timePattern) else { return nil }

        let range = NSRange(trimmed.startIndex..., in: trimmed)
        let minutes = regex.matches(in: trimmed, range: range).compactMap { match -> Int? in
            guard let matchRange = Range(match.range(at: 1), in: trimmed) else { return nil }
            return DealHours.toMinutes(string: String(trimmed[matchRange]))
        }

        guard minutes.count >= 2,
              let earliest = minutes.min(),
              let latest = minutes.max()
        else {
            return nil
        }

        return DealHours.makeBetween(start: earliest, end: latest)
    }

    private static func parseHoursFromRange(in text: String) -> DealHours? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let pattern = #"(?i)^\d+\s*(?:hrs?|hours?)\s+from\s+(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
              let rangeRange = Range(match.range(at: 1), in: trimmed)
        else {
            return nil
        }

        return DealHours.parse(String(trimmed[rangeRange]))
    }

    private static func parseBetweenTime(in text: String) -> DealHours? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let time = #"\d{1,2}(?:[:.]\d{2})?\s*(?:am|pm)?"#
        let betweenPattern = #"(?i)between\s+(\#(time))\s*(?:-|–|to)\s*(\#(time))"#
        guard let regex = try? NSRegularExpression(pattern: betweenPattern),
              let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
              let startRange = Range(match.range(at: 1), in: trimmed),
              let endRange = Range(match.range(at: 2), in: trimmed),
              let start = DealHours.toMinutes(string: String(trimmed[startRange])),
              let end = DealHours.toMinutes(string: String(trimmed[endRange]))
        else {
            return nil
        }

        return DealHours.makeBetween(start: start, end: end)
    }
}
