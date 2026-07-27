//Created by Alex Skorulis on 27/7/2026.

import Foundation
import Testing
@testable import DealScraper

struct NewZealandAddressParserTests {

    private let parser = NewZealandAddressParser()

    @Test func parsesSuburbAndPostcodeWithoutCountry() {
        let result = parser.parse(from: "88 Beach Street, Queenstown 9300")
        #expect(result?.suburb == "Queenstown")
        #expect(result?.postcode == "9300")
        #expect(result?.state == "")
    }

    @Test func parsesSuburbTownAndPostcodeWithoutCountry() {
        let result = parser.parse(from: "3 Murchison Road, Frankton, Queenstown 9300")
        #expect(result?.suburb == "Frankton")
        #expect(result?.postcode == "9300")
        #expect(result?.state == "")
    }

    @Test func parsesSuburbAndPostcodeWithNewZealandSuffix() {
        let result = parser.parse(from: "14 Camp St, Queenstown 9300, New Zealand")
        #expect(result?.suburb == "Queenstown")
        #expect(result?.postcode == "9300")
        #expect(result?.state == "")
    }

    @Test func parsesSuburbTownAndPostcodeWithNewZealandSuffix() {
        let result = parser.parse(
            from: "1 Lake Esplanade, Fernhill, Queenstown 9300, New Zealand"
        )
        #expect(result?.suburb == "Fernhill")
        #expect(result?.postcode == "9300")
        #expect(result?.state == "")
    }

    @Test func parsesSuburbRegionAndPostcode() {
        let result = parser.parse(from: "42 Ardmore St, Wanaka Otago 9305")
        #expect(result?.suburb == "Wanaka")
        #expect(result?.postcode == "9305")
        #expect(result?.state == "Otago")
    }

    @Test func parsesTownThatIsAlsoARegionAsState() {
        let result = parser.parse(from: "123 Queen Street, Auckland Central, Auckland 1010")
        #expect(result?.suburb == "Auckland Central")
        #expect(result?.postcode == "1010")
        #expect(result?.state == "Auckland")
    }

    @Test func parsesStandaloneAddress() {
        let result = parser.parse(from: "Frankton 9300")
        #expect(result?.suburb == "Frankton")
        #expect(result?.postcode == "9300")
        #expect(result?.state == "")
    }

    @Test func returnsNilForEmptyAddress() {
        #expect(parser.parse(from: "") == nil)
        #expect(parser.parse(from: "   ") == nil)
    }

    @Test func returnsNilForAddressWithoutPostcode() {
        #expect(parser.parse(from: "1 Rees St, Queenstown") == nil)
    }

    @Test func returnsNilForAustralianAddress() {
        #expect(parser.parse(from: "123 George St, Sydney NSW 2000") == nil)
        #expect(parser.parse(from: "123 George St, Sydney NSW 2000, Australia") == nil)
    }

    @Test func returnsNilForOverseasAddress() {
        #expect(
            parser.parse(from: "10 Downing Street, London SW1A 2AA, United Kingdom")
                == nil
        )
    }
}
