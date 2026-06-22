//Created by Alex Skorulis on 22/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct SuburbExtractorTests {

    @Test func extractsSuburbAndPostcodeFromAustralianAddress() {
        let result = SuburbExtractor.extract(from: "123 George St, Sydney NSW 2000")
        #expect(result?.name == "Sydney")
        #expect(result?.postcode == "2000")
    }

    @Test func extractsSuburbFromAddressWithoutPostcode() {
        let result = SuburbExtractor.extract(from: "1 Circular Quay, Sydney")
        #expect(result?.name == "Sydney")
        #expect(result?.postcode == nil)
    }

    @Test func extractsSuburbFromAddressWithAustraliaSuffix() {
        let result = SuburbExtractor.extract(
            from: "42 Crown St, Surry Hills NSW 2010, Australia"
        )
        #expect(result?.name == "Surry Hills")
        #expect(result?.postcode == "2010")
    }

    @Test func extractsSuburbFromStandaloneAddressWithAustraliaSuffix() {
        let result = SuburbExtractor.extract(from: "Glebe NSW 2037, Australia")
        #expect(result?.name == "Glebe")
        #expect(result?.postcode == "2037")
    }

    @Test func returnsNilForEmptyAddress() {
        #expect(SuburbExtractor.extract(from: "") == nil)
        #expect(SuburbExtractor.extract(from: "   ") == nil)
    }
}
