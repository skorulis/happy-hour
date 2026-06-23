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
        #expect(deal.title == "Cheeseburger Tuesdays")
        #expect(deal.details == ["Ten dollar beef or vegan cheeseburgers with chips"])
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

    @Test func parsesTillTimeAsUntilEndOfRange() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "LATE NIGHT SPECIAL",
            details: ["$5 BEERS"],
            days: ["FRIDAY"],
            times: ["till 10pm"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.times == [.between(0, 22 * 60)])
    }

    @Test func parsesFromTillTimeRange() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "HAPPY HOUR",
            details: ["$8 WINES"],
            days: ["FRIDAY"],
            times: ["from 4pm till 10pm"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.times == [.between(16 * 60, 22 * 60)])
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

    @Test func removesTitleRepeatedInDetails() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "HAPPY HOUR",
            details: ["HAPPY HOUR", "$8 WINES"],
            days: ["FRIDAY"],
            times: ["4PM - 6PM"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "Happy Hour")
        #expect(deal.details == ["$8 Wines"])
    }

    @Test func removesDuplicateDetailLines() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "TACO TUESDAY",
            details: ["$2 TACOS", "$2 TACOS", "$3 BEERS"],
            days: ["TUESDAY"],
            times: ["all day"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.details == ["$2 Tacos", "$3 Beers"])
    }

    @Test func deduplicatesDetailsCaseInsensitively() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "WING WEDNESDAY",
            details: ["$1 WINGS", "$1 wings"],
            days: ["WEDNESDAY"],
            times: ["all day"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.details == ["$1 Wings"])
    }

    @Test func removesConditionsDuplicatingTitleOrDetails() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "STEAK NIGHT",
            details: ["$22 STEAK"],
            conditions: ["STEAK NIGHT", "$22 STEAK", "dine-in only"],
            days: ["TUESDAY"],
            times: ["all day"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.conditions == ["dine-in only"])
    }

    @Test func appendsLeadingPriceDetailToTitle() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "STEAK NIGHT",
            details: ["$22", "Premium cut with sides"],
            days: ["MONDAY"],
            times: ["all day"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "Steak Night $22")
        #expect(deal.details == ["Premium cut with sides"])
    }

    @Test func usesLeadingPriceAsTitleWhenTitleIsEmpty() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "",
            details: ["$39PP", "Sunday roast with all the trimmings"],
            days: ["SUNDAY"],
            times: ["all day"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "$39PP")
        #expect(deal.details == ["Sunday roast with all the trimmings"])
    }

    @Test func doesNotAppendPricePlusDescriptionDetailToTitle() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "HAPPY HOUR",
            details: ["$8 SCHOONERS"],
            days: ["FRIDAY"],
            times: ["4PM - 6PM"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "Happy Hour")
        #expect(deal.details == ["$8 Schooners"])
    }

    @Test func doesNotDuplicateLeadingPriceAlreadyInTitle() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "$22 STEAK NIGHT",
            details: ["$22", "Raise the Steaks"],
            days: ["MONDAY"],
            times: ["all day"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "$22 Steak Night")
        #expect(deal.details == ["Raise the steaks"])
    }

    @Test func sentenceCasesMultilineDetails() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "STEAK NIGHT",
            details: ["RAISE THE STEAKS\nWITH ALL THE TRIMMINGS\n$22 EACH"],
            days: ["MONDAY"],
            times: ["all day"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.details == ["Raise the steaks\nWith all the trimmings\n$22 Each"])
    }
}
