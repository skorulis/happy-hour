//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct DealMapperTests {

    @Test func mapsRawDealWithDaysAndTimes() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "CHEESEBURGER TUESDAYS",
            details: ["TEN DOLLAR BEEF OR VEGAN CHEESEBURGERS WITH CHIPS"],
            days: ["EVERY TUES"],
            times: ["all day"]
        )

        let deals = DealMapper.map([raw])

        #expect(deals.count == 1)
        let deal = try #require(deals.first)
        #expect(deal.title == "CHEESEBURGER TUESDAYS")
        #expect(deal.details.count == 1)
        #expect(deal.days == [.tuesday])
        #expect(deal.times == [.allDay])
    }

    @Test func parsesTimeRangeFromRawDeal() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "HAPPY HOUR",
            details: ["$8 SCHOONERS"],
            days: ["TUES - THURS"],
            times: ["4PM - 6PM"]
        )

        let deals = DealMapper.map([raw])
        let deal = try #require(deals.first)

        #expect(deal.days == [.tuesday, .wednesday, .thursday])
        #expect(deal.times.contains(.between(16 * 60, 18 * 60)))
    }

    @Test func expandsMondayToFridayDayRange() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "HAPPY HOUR",
            details: ["$8 SCHOONERS"],
            days: ["MONDAY - FRIDAY"],
            times: ["4PM - 6PM"]
        )

        let deals = DealMapper.map([raw])
        let deal = try #require(deals.first)

        #expect(deal.days == [.monday, .tuesday, .wednesday, .thursday, .friday])
    }

    @Test func supplementsMissingTimesFromContext() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "HAPPY HOUR",
            details: ["$8 SCHOONERS"],
            days: ["FRIDAY"],
            times: []
        )

        let deals = DealMapper.map([raw], supplementFrom: ["TUES - THURS 4PM - 6PM / FRI 3PM - 5PM"])
        let deal = try #require(deals.first)

        #expect(!deal.times.isEmpty)
    }

    @Test func mergesDealsWithSharedText() {
        let first = DealExtractionPayload.RawDeal(
            title: "HAPPY HOUR",
            details: ["$8 WINES"],
            days: ["TUESDAY"],
            times: ["4PM - 6PM"]
        )
        let second = DealExtractionPayload.RawDeal(
            title: "",
            details: ["$8 WINES"],
            days: ["THURSDAY"],
            times: ["4PM - 6PM"]
        )

        let deals = DealMapper.map([first, second])

        #expect(deals.count == 1)
        #expect(deals.first?.days.contains(.tuesday) == true)
        #expect(deals.first?.days.contains(.thursday) == true)
    }

    @Test func parsesDotSeparatedTimeFromRawDeal() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "HAPPY HOUR",
            details: ["$8 SCHOONERS"],
            days: ["FRIDAY"],
            times: ["6.30pm"]
        )

        let deals = DealMapper.map([raw])
        let deal = try #require(deals.first)

        #expect(deal.times == [.from(18 * 60 + 30)])
    }

    @Test func stripsLeadingAsteriskFromConditions() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "STEAK NIGHT",
            details: ["$22 STEAK"],
            conditions: ["*only available with bar service"],
            days: ["TUESDAY"],
            times: ["all day"]
        )

        let deals = DealMapper.map([raw])
        let deal = try #require(deals.first)

        #expect(deal.conditions == ["only available with bar service"])
    }

    @Test func filtersEmptyRawDeals() {
        let raw = DealExtractionPayload.RawDeal(
            title: "   ",
            details: [],
            days: [],
            times: []
        )

        let deals = DealMapper.map([raw])

        #expect(deals.isEmpty)
    }
}
