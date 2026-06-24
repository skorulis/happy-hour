//Created by Alex Skorulis on 24/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct DealTimeParserTests {

    @Test func parsesFromPrefixedCompactTimeRange() {
        #expect(DealTimeParser.parse(["FROM 4-6PM"]) == [.between(16 * 60, 18 * 60)])
    }

    @Test func parsesTimeRangeFromRawDealTimes() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "HAPPY HOUR",
            details: ["$8 SCHOONERS"],
            days: ["FRIDAY"],
            times: ["FROM 4-6PM"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.times == [.between(16 * 60, 18 * 60)])
    }

    @Test func parsesTillTimeAsUntilEndOfRange() {
        #expect(DealTimeParser.parse(["till 10pm"]) == [.between(0, 22 * 60)])
    }

    @Test func parsesFromTillTimeRange() {
        #expect(DealTimeParser.parse(["from 4pm till 10pm"]) == [.between(16 * 60, 22 * 60)])
    }

    @Test func parsesStartTillEndTimeRange() {
        #expect(DealTimeParser.parse(["3PM 'TIL 6PM"]) == [.between(15 * 60, 18 * 60)])
    }

    @Test func parsesAllDayTokens() {
        #expect(DealTimeParser.parse(["all day"]) == [.allDay])
        #expect(DealTimeParser.parse(["ALL DAY", "all-day"]) == [.allDay])
    }

    @Test func returnsEmptyForMissingTimes() {
        #expect(DealTimeParser.parse([]) == [])
    }

    @Test func extractsTimeRangeFromSupplementText() {
        let times = DealTimeParser.timesInText("TUES - THURS 4PM - 6PM / FRI 3PM - 5PM")
        #expect(!times.isEmpty)
    }
}
