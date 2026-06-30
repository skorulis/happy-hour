//Created by Alex Skorulis on 24/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct DealTimeParserTests {

    @Test func parsesFromPrefixedCompactTimeRange() {
        #expect(DealTimeParser.parse(["FROM 4-6PM"]) == [.between(16 * 60, 18 * 60)])
    }

    @Test func parsesCompactTimeRangeWithTrailingPunctuation() {
        #expect(DealTimeParser.parse(["2-4pm!"]) == [.between(14 * 60, 16 * 60)])
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

    @Test func parsesAvailableFromTimeRange() {
        #expect(DealTimeParser.parse(["Available from 11:30am –3pm"]) == [.between(11 * 60 + 30, 15 * 60)])
    }

    @Test func parsesStartTillEndTimeRange() {
        #expect(DealTimeParser.parse(["3PM 'TIL 6PM"]) == [.between(15 * 60, 18 * 60)])
    }

    @Test func parsesPmTillPmTimeRange() {
        #expect(DealTimeParser.parse(["4pm 'til 6pm"]) == [.between(16 * 60, 18 * 60)])
        #expect(DealTimeParser.parse(["4pm \u{2019}til 6pm"]) == [.between(16 * 60, 18 * 60)])
    }

    @Test func parsesBareHourTillPmTimeRange() {
        #expect(DealTimeParser.parse(["12 'TIL 3PM"]) == [.between(12 * 60, 15 * 60)])
        #expect(DealTimeParser.parse(["12 \u{2019}TIL 3PM"]) == [.between(12 * 60, 15 * 60)])
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

    @Test func parsesParenthesizedTimeRange() {
        #expect(DealTimeParser.parse(["(11 AM - 2 PM )"]) == [.between(11 * 60, 14 * 60)])
    }

    @Test func parsesNoonTimeRange() {
        #expect(DealTimeParser.parse(["NOON - 4PM"]) == [.between(12 * 60, 16 * 60)])
    }

    @Test func parsesStartBetweenTimeRange() {
        #expect(
            DealTimeParser.parse(["with a start between 12pm-3:15pm."])
                == [.between(12 * 60, 15 * 60 + 15)]
        )
    }

    @Test func parsesMarkdownBoldWrappedTimeRange() {
        #expect(DealTimeParser.parse(["**3PM–6PM**"]) == [.between(15 * 60, 18 * 60)])
    }

    @Test func parsesMarkdownBoldWrappedTillCloseTime() {
        #expect(DealTimeParser.parse(["**9PM till close**"]) == [.from(21 * 60)])
    }

    @Test func parsesFromAndDrawnAtSplitTimeRange() {
        let expected = [DealHours.between(17 * 60, 19 * 60 + 30)]
        #expect(DealTimeParser.parse(["FROM 5PM", "DRAWN AT 7:30PM"]) == expected)
        #expect(DealTimeParser.parse(["5pm-7:30pm"]) == expected)
    }
}
