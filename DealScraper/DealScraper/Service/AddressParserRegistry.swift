//Created by Alex Skorulis on 27/7/2026.

import Foundation

enum AddressParserRegistry {
    static func parser(forCountryIso3 iso3: String) -> (any AddressParser)? {
        switch iso3 {
        case Country.australia.iso3:
            return AustraliaAddressParser()
        default:
            return nil
        }
    }

    static func parser(for country: Country) -> (any AddressParser)? {
        parser(forCountryIso3: country.iso3)
    }

    /// Country-specific parser when known; otherwise Australia (legacy default).
    static func parser(forCountryIso3OrDefault iso3: String?) -> any AddressParser {
        if let iso3, let parser = parser(forCountryIso3: iso3) {
            return parser
        }
        return AustraliaAddressParser()
    }
}
