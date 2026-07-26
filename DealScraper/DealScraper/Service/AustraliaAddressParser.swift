//Created by Alex Skorulis on 22/6/2026.

import Foundation

struct AustraliaAddressParser: AddressParser {
    private static let streetSuburbPattern =
        #/,\s*([^,]+?)\s+(?i)(NSW|VIC|QLD|SA|WA|TAS|NT|ACT)\s+(\d{4})\s*(?:,\s*Australia)?\s*$/#

    private static let standaloneSuburbPattern =
        #/^([^,]+?)\s+(?i)(NSW|VIC|QLD|SA|WA|TAS|NT|ACT)\s+(\d{4})\s*(?:,\s*Australia)?\s*$/#

    func parse(from formattedAddress: String) -> ParsedAddress? {
        let trimmed = formattedAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        for pattern in [Self.streetSuburbPattern, Self.standaloneSuburbPattern] {
            if let match = trimmed.firstMatch(of: pattern) {
                let suburb = String(match.1).trimmingCharacters(in: .whitespacesAndNewlines)
                let state = String(match.2).uppercased()
                let postcode = String(match.3)
                guard !suburb.isEmpty else { return nil }
                return ParsedAddress(suburb: suburb, state: state, postcode: postcode)
            }
        }

        return nil
    }
}
