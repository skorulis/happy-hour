//Created by Alex Skorulis on 10/7/2026.

import Foundation

nonisolated enum NthWeekdayOfMonthDetector {

    private static let weekdayPattern =
        #"(?:mon(?:day)?|tues?(?:day)?|wed(?:nesday)?|thu(?:rs?)?(?:day)?|fri(?:day)?|sat(?:urday)?|sun(?:day)?)"#

    private static let ordinalPattern =
        #"(?:first|second|third|fourth|last|\d+(?:st|nd|rd|th))"#

    private static let monthQualifierPattern =
        #"of\s+(?:each|every|the)\s+month"#

    private static let slashMonthQualifierPattern =
        #"of\s+\(\s*each\s*/\s*every\s*/\s*the\s*\)\s+month"#

    private static let slashOrdinalPattern =
        #"first\s*/\s*second\s*/\s*third\s*/\s*fourth\s*/\s*last"#

    private static let patterns: [NSRegularExpression] = {
        let candidates = [
            #"(?i)\b\#(ordinalPattern)\s+\#(weekdayPattern)\b[\s\S]*?\#(monthQualifierPattern)\b"#,
            #"(?i)\b\#(ordinalPattern)\s+\#(weekdayPattern)\b[\s\S]*?\#(slashMonthQualifierPattern)\b"#,
            #"(?i)\(\s*\#(slashOrdinalPattern)\s*\)\s+\#(weekdayPattern)\b[\s\S]*?\#(monthQualifierPattern)\b"#,
            #"(?i)\(\s*\#(slashOrdinalPattern)\s*\)\s+\#(weekdayPattern)\b[\s\S]*?\#(slashMonthQualifierPattern)\b"#,
        ]
        return candidates.compactMap { try? NSRegularExpression(pattern: $0) }
    }()

    static func isMatch(title: String?, details: [String], conditions: [String], days: [String]) -> Bool {
        isMatch(in: [title].compactMap { $0 } + details + conditions + days)
    }

    static func isMatch(in texts: [String]) -> Bool {
        texts.contains { containsPattern($0) }
    }

    private static func containsPattern(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let range = NSRange(trimmed.startIndex..., in: trimmed)
        return patterns.contains { regex in
            regex.firstMatch(in: trimmed, range: range) != nil
        }
    }
}
