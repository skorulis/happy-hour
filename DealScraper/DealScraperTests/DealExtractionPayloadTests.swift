//Created by Alex Skorulis on 2/7/2026.

import Foundation
import Testing
@testable import DealScraper

struct DealExtractionPayloadTests {

    @Test func decodesPromotionDates() throws {
        let json = """
        {"deals":[{"title":"Black Friday Gift Card Sale – 25% Off","details":["25% off all gift cards"],"days":[],"times":["all day"],"conditions":[],"promotionDates":["Friday, 14 November – Monday, 1 December 2025"]}]}
        """
        let payload = try JSONDecoder().decode(DealExtractionPayload.self, from: Data(json.utf8))

        #expect(payload.deals.count == 1)
        #expect(payload.deals[0].promotionDates == ["Friday, 14 November – Monday, 1 December 2025"])
    }

    @Test func decodesNullPromotionDates() throws {
        let json = """
        {"deals":[{"title":"Happy Hour","details":["$8 wines"],"days":["Friday"],"times":["4PM - 6PM"],"conditions":[],"promotionDates":null}]}
        """
        let payload = try JSONDecoder().decode(DealExtractionPayload.self, from: Data(json.utf8))

        #expect(payload.deals.count == 1)
        #expect(payload.deals[0].promotionDates == nil)
    }

    @Test func decodesMissingPromotionDatesAsNil() throws {
        let json = """
        {"deals":[{"title":"Happy Hour","details":["LET'S DRINK TO THAT!"],"days":["EVERY DAY"],"times":["5PM - 8PM"],"conditions":["Conditions apply."]}]}
        """
        let payload = try JSONDecoder().decode(DealExtractionPayload.self, from: Data(json.utf8))

        #expect(payload.deals.count == 1)
        #expect(payload.deals[0].promotionDates == nil)
    }

    @Test func decodesMountbattenHappyHourFixtureWithoutPromotionDates() throws {
        let payload = try DealExtractionPayload.fixture(named: "mountbatten-happy-hour")

        #expect(payload.deals.count == 1)
        #expect(payload.deals[0].promotionDates == nil)
    }

    @Test func decodesHarbourfrontBlackFridayFixture() throws {
        let payload = try DealExtractionPayload.fixture(named: "harbourfront-black-friday")

        #expect(payload.deals.count == 1)
        #expect(payload.deals[0].title == "Black Friday Gift Card Sale – 25% Off")
        #expect(payload.deals[0].promotionDates == ["Friday, 14 November – Monday, 1 December 2025"])
    }
}
