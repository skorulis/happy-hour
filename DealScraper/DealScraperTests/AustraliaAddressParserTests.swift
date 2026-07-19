//Created by Alex Skorulis on 22/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct AustraliaAddressParserTests {

    @Test func parsesSuburbStateAndPostcodeFromAustralianAddress() {
        let result = AustraliaAddressParser.parse(from: "123 George St, Sydney NSW 2000")
        #expect(result?.suburb == "Sydney")
        #expect(result?.postcode == "2000")
        #expect(result?.state == "NSW")
    }

    @Test func parsesAddressWithAustraliaSuffix() {
        let result = AustraliaAddressParser.parse(
            from: "42 Crown St, Surry Hills NSW 2010, Australia"
        )
        #expect(result?.suburb == "Surry Hills")
        #expect(result?.postcode == "2010")
        #expect(result?.state == "NSW")
    }

    @Test func parsesStandaloneAddressWithAustraliaSuffix() {
        let result = AustraliaAddressParser.parse(from: "Glebe NSW 2037, Australia")
        #expect(result?.suburb == "Glebe")
        #expect(result?.postcode == "2037")
        #expect(result?.state == "NSW")
    }

    @Test func returnsNilForEmptyAddress() {
        #expect(AustraliaAddressParser.parse(from: "") == nil)
        #expect(AustraliaAddressParser.parse(from: "   ") == nil)
    }

    @Test func returnsNilForAddressWithoutStateAndPostcode() {
        #expect(AustraliaAddressParser.parse(from: "1 Circular Quay, Sydney") == nil)
    }

    @Test func returnsNilForOverseasAddress() {
        #expect(
            AustraliaAddressParser.parse(from: "1600 Amphitheatre Parkway, Mountain View, CA 94043")
                == nil
        )
        #expect(
            AustraliaAddressParser.parse(from: "10 Downing Street, London SW1A 2AA, United Kingdom")
                == nil
        )
    }
}
