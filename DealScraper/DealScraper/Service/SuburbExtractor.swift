//Created by Alex Skorulis on 22/6/2026.

import Foundation

enum SuburbExtractor {
    private static let statePostcodePattern =
        #/,\s*([^,]+?)\s+(?i)(NSW|VIC|QLD|SA|WA|TAS|NT|ACT)\s+(\d{4})\s*(?:,\s*Australia)?\s*$/#

    static func extract(from formattedAddress: String) -> (name: String, postcode: String?)? {
        let trimmed = formattedAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let match = trimmed.firstMatch(of: statePostcodePattern) {
            let suburb = String(match.1).trimmingCharacters(in: .whitespacesAndNewlines)
            let postcode = String(match.3)
            guard !suburb.isEmpty else { return nil }
            return (suburb, postcode)
        }

        let parts = trimmed.split(separator: ",", omittingEmptySubsequences: true)
        guard let last = parts.last else { return nil }
        let suburb = last.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !suburb.isEmpty else { return nil }
        return (suburb, nil)
    }
}
