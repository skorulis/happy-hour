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

    @Test func returnsNewZealandParserForNZL() {
        let parser = AddressParserRegistry.parser(forCountryIso3: Country.newZealand.iso3)
        #expect(parser != nil)
        let parsed = parser?.parse(from: "14 Camp St, Queenstown 9300, New Zealand")
        #expect(parsed?.suburb == "Queenstown")
        #expect(parsed?.postcode == "9300")
    }

    @Test func defaultFallbackIsAustralia() {
        let parser = AddressParserRegistry.parser(forCountryIso3OrDefault: nil)
        let parsed = parser.parse(from: "Glebe NSW 2037, Australia")
        #expect(parsed?.suburb == "Glebe")
    }

    @Test func resolvesIso3FromPlacesRegionCode() {
        #expect(Country.iso3(forRegionOrIso3: "AU") == Country.australia.iso3)
        #expect(Country.iso3(forRegionOrIso3: "nz") == Country.newZealand.iso3)
        #expect(Country.iso3(forRegionOrIso3: "NZL") == Country.newZealand.iso3)
        #expect(Country.iso3(forRegionOrIso3: "  ") == nil)
        #expect(Country.iso3(forRegionOrIso3: "XX") == nil)
    }
}
