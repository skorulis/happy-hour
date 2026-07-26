//Created by Alex Skorulis on 22/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct AustraliaAddressParserTests {

    private let parser = AustraliaAddressParser()

    @Test func parsesSuburbStateAndPostcodeFromAustralianAddress() {
        let result = parser.parse(from: "123 George St, Sydney NSW 2000")
        #expect(result?.suburb == "Sydney")
        #expect(result?.postcode == "2000")
        #expect(result?.state == "NSW")
    }

    @Test func parsesAddressWithAustraliaSuffix() {
        let result = parser.parse(
            from: "42 Crown St, Surry Hills NSW 2010, Australia"
        )
        #expect(result?.suburb == "Surry Hills")
        #expect(result?.postcode == "2010")
        #expect(result?.state == "NSW")
    }

    @Test func parsesStandaloneAddressWithAustraliaSuffix() {
        let result = parser.parse(from: "Glebe NSW 2037, Australia")
        #expect(result?.suburb == "Glebe")
        #expect(result?.postcode == "2037")
        #expect(result?.state == "NSW")
    }

    @Test func returnsNilForEmptyAddress() {
        #expect(parser.parse(from: "") == nil)
        #expect(parser.parse(from: "   ") == nil)
    }

    @Test func returnsNilForAddressWithoutStateAndPostcode() {
        #expect(parser.parse(from: "1 Circular Quay, Sydney") == nil)
    }

    @Test func returnsNilForOverseasAddress() {
        #expect(
            parser.parse(from: "1600 Amphitheatre Parkway, Mountain View, CA 94043")
                == nil
        )
        #expect(
            parser.parse(from: "10 Downing Street, London SW1A 2AA, United Kingdom")
                == nil
        )
    }
}
