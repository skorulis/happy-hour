//Created by Alex Skorulis on 22/6/2026.

import Foundation

enum SuburbExtractor {
    private static let streetSuburbPattern =
        #/,\s*([^,]+?)\s+(?i)(NSW|VIC|QLD|SA|WA|TAS|NT|ACT)\s+(\d{4})\s*(?:,\s*Australia)?\s*$/#

    private static let standaloneSuburbPattern =
        #/^([^,]+?)\s+(?i)(NSW|VIC|QLD|SA|WA|TAS|NT|ACT)\s+(\d{4})\s*(?:,\s*Australia)?\s*$/#

    static func extract(from formattedAddress: String) -> (name: String, postcode: String?)? {
        let trimmed = formattedAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        for pattern in [streetSuburbPattern, standaloneSuburbPattern] {
            if let match = trimmed.firstMatch(of: pattern) {
                let suburb = String(match.1).trimmingCharacters(in: .whitespacesAndNewlines)
                let postcode = String(match.3)
                guard !suburb.isEmpty else { return nil }
                return (suburb, postcode)
            }
        }

        let parts = trimmed
            .split(separator: ",", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.caseInsensitiveCompare("Australia") != .orderedSame }

        guard let suburb = parts.last else { return nil }
        return (suburb, nil)
    }
}
