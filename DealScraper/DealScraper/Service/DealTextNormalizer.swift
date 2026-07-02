//Created by Alex Skorulis on 2/7/2026.

import Foundation

nonisolated enum DealTextNormalizer {

    static func prepareTitle(_ title: String) -> String {
        title
            .components(separatedBy: .newlines)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func prepareDetails(_ details: [String]) -> [String] {
        details
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func formatTitle(_ title: String) -> String {
        guard !title.isEmpty, !isPriceLine(title) else { return title }
        return title.capitalized
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
        #"(?i)^\$\s*\d+(?:\.\d{2})?[a-z]*$"#,
        #"(?i)^half[\s-]?price$"#,
    ]

    private static func sentenceCased(_ text: String) -> String {
        text
            .components(separatedBy: .newlines)
            .map { line in
                guard !line.isEmpty else { return line }
                return sentenceCasedLine(line)
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
