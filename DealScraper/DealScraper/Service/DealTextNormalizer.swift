//Created by Alex Skorulis on 2/7/2026.

import Foundation

nonisolated enum DealTextNormalizer {

    static func prepareTitle(_ title: String) -> String {
        title
            .components(separatedBy: .newlines)
            .joined(separator: " ")
    }

    static func prepareDetails(_ details: [String]) -> [String] {
        details
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func formatTitle(_ title: String) -> String {
        guard !title.isEmpty, !isPriceLine(title) else { return title }
        return lowercaseUnitsAfterNumbers(title.capitalized)
    }

    static func normalizeDetails(_ details: [String]) -> [String] {
        details.map(sentenceCased)
    }

    static func normalizeConditions(_ conditions: [String]) -> [String] {
        conditions
            .map(normalizeCondition)
            .filter { !$0.isEmpty }
    }

    static func comparisonKey(_ line: String) -> String {
        line
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    static func isPriceLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let range = NSRange(trimmed.startIndex..., in: trimmed)
        return priceLinePatterns.contains { pattern in
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
            guard let match = regex.firstMatch(in: trimmed, range: range) else { return false }
            return match.range.location == 0 && match.range.length == trimmed.utf16.count
        }
    }

    private static let priceLinePatterns = [
        #"(?i)^\$\s*\d+(?:\.\d{1,2})?[a-z]*$"#,
        #"(?i)^half[\s-]?price$"#,
    ]

    private static let unitsAfterNumberPattern = #"(?i)(\d+(?:\.\d+)?)(\s*)(kg|ml|mg|lbs|lb|oz|cl|g|l|am|pm|pp)\b"#

    private static func lowercaseUnitsAfterNumbers(_ title: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: unitsAfterNumberPattern) else { return title }

        var result = title
        let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result)).reversed()
        for match in matches {
            guard let range = Range(match.range, in: result),
                  let numberRange = Range(match.range(at: 1), in: result),
                  let spaceRange = Range(match.range(at: 2), in: result),
                  let unitRange = Range(match.range(at: 3), in: result)
            else { continue }

            let replacement =
                String(result[numberRange])
                + String(result[spaceRange])
                + String(result[unitRange]).lowercased()
            result.replaceSubrange(range, with: replacement)
        }
        return result
    }

    private static func sentenceCased(_ text: String) -> String {
        text
            .components(separatedBy: .newlines)
            .map { line in
                guard !line.isEmpty else { return line }
                return lowercaseUnitsAfterNumbers(sentenceCasedLine(line))
            }
            .joined(separator: "\n")
    }

    private static func sentenceCasedLine(_ line: String) -> String {
        let lowercased = line.lowercased()
        guard let firstLetterIndex = lowercased.firstIndex(where: { $0.isLetter }) else {
            return lowercased
        }
        var result = lowercased
        result.replaceSubrange(
            firstLetterIndex ... firstLetterIndex,
            with: String(lowercased[firstLetterIndex]).uppercased()
        )
        return result
    }

    private static func normalizeCondition(_ string: String) -> String {
        var trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("*") {
            trimmed = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if trimmed.hasPrefix("\\*") {
            trimmed = String(trimmed.dropFirst().dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return trimmed
    }
}

extension String {
    
    nonisolated static let characterSet = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "\\*._|"))
    
    nonisolated func cleanLine() -> String {
        trimmingCharacters(in: Self.characterSet)
    }
}
