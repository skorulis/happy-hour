//Created by Alex Skorulis on 27/7/2026.

import Foundation
import Testing
@testable import DealScraper

struct AddressParserRegistryTests {

    @Test func returnsAustraliaParserForAUS() {
        let parser = AddressParserRegistry.parser(forCountryIso3: Country.australia.iso3)
        #expect(parser != nil)
        let parsed = parser?.parse(from: "123 George St, Sydney NSW 2000")
        #expect(parsed?.suburb == "Sydney")
        #expect(parsed?.postcode == "2000")
        #expect(parsed?.state == "NSW")
    }

    @Test func returnsNilForNewZealandUntilParserExists() {
        #expect(AddressParserRegistry.parser(forCountryIso3: Country.newZealand.iso3) == nil)
    }

    @Test func defaultFallbackIsAustralia() {
        let parser = AddressParserRegistry.parser(forCountryIso3OrDefault: nil)
        let parsed = parser.parse(from: "Glebe NSW 2037, Australia")
        #expect(parsed?.suburb == "Glebe")
    }
}
