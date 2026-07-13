//Created by Alex Skorulis on 10/7/2026.

import Foundation

nonisolated enum SingleDateDetector {

    private static let weekdayPattern =
        #"(?:mon(?:day)?|tues?(?:day)?|wed(?:nesday)?|thu(?:rs?)?(?:day)?|fri(?:day)?|sat(?:urday)?|sun(?:day)?)"#

    private static let monthPattern =
        #"(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|july?|aug(?:ust)?|sep(?:t(?:ember)?)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)"#

    /// OCR-tolerant day number: Vision often reads `1` as `I` or `l`.
    private static let dayPattern = #"[0-9il1IL|]{1,2}(?:st|nd|rd|th)?"#

    private static let patterns: [NSRegularExpression] = {
        let candidates = [
            #"(?i)\b(?:\#(weekdayPattern)\s+)?\#(monthPattern)\.?\s+\#(dayPattern)\b"#,
            #"(?i)\b\#(dayPattern)(?:\s+of)?\s+\#(monthPattern)(?:\.?\s+\d{4})?\b"#,
            #"(?i)\b\#(monthPattern)(?:\.?\s+\#(dayPattern)(?:,\s*\d{4})?|\s+\#(dayPattern)(?:,\s*\d{4})?)\b"#,
            #"(?i)\b\d{4}[-/.]\d{1,2}[-/.]\d{1,2}\b"#,
            #"(?i)\b\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4}\b"#,
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
        let trimmed = OCRTextNormalizer.normalize(text)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let range = NSRange(trimmed.startIndex..., in: trimmed)
        return patterns.contains { regex in
            regex.firstMatch(in: trimmed, range: range) != nil
        }
    }
}

