//Created by Alex Skorulis on 27/7/2026.

import Foundation

struct NewZealandAddressParser: AddressParser {
    /// Longest-first so multi-word regions match before shorter names.
    private static let regions: [String] = [
        "Manawatu-Wanganui",
        "Manawatū-Whanganui",
        "Bay of Plenty",
        "Hawke's Bay",
        "Hawkes Bay",
        "West Coast",
        "Marlborough",
        "Canterbury",
        "Southland",
        "Northland",
        "Wellington",
        "Taranaki",
        "Gisborne",
        "Waikato",
        "Auckland",
        "Tasman",
        "Nelson",
        "Otago",
    ]

    private static let regionAlternation = regions
        .map { NSRegularExpression.escapedPattern(for: $0) }
        .joined(separator: "|")

    /// `street, Suburb, Town Postcode, New Zealand`
    private static let streetSuburbTownPattern =
        #/,\s*([^,]+),\s*([^,]+?)\s+(\d{4})\s*,\s*New Zealand\s*$/#

    /// `street, Suburb Region Postcode(, New Zealand)?`
    private static var streetSuburbRegionPattern: Regex<(Substring, Substring, Substring, Substring)> {
        try! Regex(#",\s*([^,]+?)\s+(?i)(\#(regionAlternation))\s+(\d{4})\s*(?:,\s*New Zealand)?\s*$"#)
    }

    /// `street, Suburb Postcode, New Zealand`
    private static let streetSuburbPattern =
        #/,\s*([^,]+?)\s+(\d{4})\s*,\s*New Zealand\s*$/#

    private static let standaloneSuburbTownPattern =
        #/^([^,]+),\s*([^,]+?)\s+(\d{4})\s*,\s*New Zealand\s*$/#

    private static var standaloneSuburbRegionPattern: Regex<(Substring, Substring, Substring, Substring)> {
        try! Regex(#"^([^,]+?)\s+(?i)(\#(regionAlternation))\s+(\d{4})\s*(?:,\s*New Zealand)?\s*$"#)
    }

    private static let standaloneSuburbPattern =
        #/^([^,]+?)\s+(\d{4})\s*,\s*New Zealand\s*$/#

    func parse(from formattedAddress: String) -> ParsedAddress? {
        let trimmed = formattedAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let match = trimmed.firstMatch(of: Self.streetSuburbTownPattern) {
            return parsed(
                suburb: String(match.1),
                townOrRegion: String(match.2),
                postcode: String(match.3)
            )
        }
        if let match = trimmed.firstMatch(of: Self.streetSuburbRegionPattern) {
            guard let state = canonicalRegion(String(match.2)) else { return nil }
            return parsed(
                suburb: String(match.1),
                state: state,
                postcode: String(match.3)
            )
        }
        if let match = trimmed.firstMatch(of: Self.streetSuburbPattern) {
            return parsed(suburb: String(match.1), state: "", postcode: String(match.2))
        }
        if let match = trimmed.firstMatch(of: Self.standaloneSuburbTownPattern) {
            return parsed(
                suburb: String(match.1),
                townOrRegion: String(match.2),
                postcode: String(match.3)
            )
        }
        if let match = trimmed.firstMatch(of: Self.standaloneSuburbRegionPattern) {
            guard let state = canonicalRegion(String(match.2)) else { return nil }
            return parsed(
                suburb: String(match.1),
                state: state,
                postcode: String(match.3)
            )
        }
        if let match = trimmed.firstMatch(of: Self.standaloneSuburbPattern) {
            return parsed(suburb: String(match.1), state: "", postcode: String(match.2))
        }

        return nil
    }

    private func parsed(suburb: String, townOrRegion: String, postcode: String) -> ParsedAddress? {
        let state = canonicalRegion(townOrRegion) ?? ""
        return parsed(suburb: suburb, state: state, postcode: postcode)
    }

    private func parsed(suburb: String, state: String, postcode: String) -> ParsedAddress? {
        let suburb = suburb.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !suburb.isEmpty else { return nil }
        return ParsedAddress(suburb: suburb, state: state, postcode: postcode)
    }

    private func canonicalRegion(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return Self.regions.first {
            $0.compare(trimmed, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }
}
