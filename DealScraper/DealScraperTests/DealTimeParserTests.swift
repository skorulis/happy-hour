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

    @Test func parsesAvailableTimeRange() {
        #expect(
            DealTimeParser.parse(["AVAILABLE 6:30–8:30PM"])
                == [.between(18 * 60 + 30, 20 * 60 + 30)]
        )
    }

    @Test func parsesStartTillEndTimeRange() {
        #expect(DealTimeParser.parse(["3PM 'TIL 6PM"]) == [.between(15 * 60, 18 * 60)])
    }

    @Test func parsesPmTillPmTimeRange() {
        #expect(DealTimeParser.parse(["4pm 'til 6pm"]) == [.between(16 * 60, 18 * 60)])
        #expect(DealTimeParser.parse(["4pm \u{2019}til 6pm"]) == [.between(16 * 60, 18 * 60)])
        #expect(DealTimeParser.parse(["6pm til' 10pm"]) == [.between(18 * 60, 22 * 60)])
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

    @Test func parsesBetweenTimeRangeWithOptionalStartPeriod() {
        #expect(
            DealTimeParser.parse(["BETWEEN 4 - 6.30PM"])
                == [.between(16 * 60, 18 * 60 + 30)]
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

    @Test func parsesFromDrawnInlineTimeRange() {
        let expected = [DealHours.between(16 * 60, 18 * 60)]
        #expect(DealTimeParser.parse(["20 TICKETS SOLD FROM 4PM DRAWN 6PM"]) == expected)
        #expect(DealTimeParser.parse(["FROM 4PM DRAWN 6PM"]) == expected)
        #expect(DealTimeParser.timesInText("20 TICKETS SOLD FROM 4PM DRAWN 6PM") == expected)
    }

    @Test func parsesFromAndDrawnSplitTimeRangeWithoutAt() {
        let expected = [DealHours.between(17 * 60, 19 * 60 + 30)]
        #expect(DealTimeParser.parse(["FROM 5PM", "DRAWN 7:30PM"]) == expected)
    }

    @Test func parsesOnSaleFromAndDrawsFromSplitTimeRange() {
        let expected = [DealHours.between(17 * 60, 18 * 60 + 30)]
        #expect(DealTimeParser.parse(["ON SALE FROM 5PM", "DRAWS FROM 6:30PM"]) == expected)
        #expect(
            DealTimeParser.parse(["ON SALE FROM 5PM DRAWS FROM 6:30PM"]) == expected
        )
    }

    @Test func parsesMultipleListedTimesAsRange() {
        #expect(
            DealTimeParser.parse(["3pm, 3:30pm & 4pm"])
                == [.between(15 * 60, 16 * 60)]
        )
    }

    @Test func parsesOvernightTimeRange() {
        #expect(DealTimeParser.parse(["10PM - 2AM"]) == [.between(22 * 60, 26 * 60)])
        #expect(DealTimeParser.parse(["from 4pm till 2am"]) == [.between(16 * 60, 26 * 60)])
    }

    @Test func parsesTimeLabelPrefixedRange() {
        #expect(DealTimeParser.parse(["Time - 2pm-5pm"]) == [.between(14 * 60, 17 * 60)])
        #expect(DealTimeParser.parse(["Time: 2pm-5pm"]) == [.between(14 * 60, 17 * 60)])
    }

    @Test func parsesHappyHourPrefixedTimeRange() {
        #expect(DealTimeParser.parse(["HAPPY HOUR 4-6PM"]) == [.between(16 * 60, 18 * 60)])
        #expect(DealTimeParser.timesInText("HAPPY HOUR 4-6PM") == [.between(16 * 60, 18 * 60)])
    }

    @Test func parsesEmbeddedTimeRangeWithLeadingLabel() {
        #expect(
            DealTimeParser.parse(["BISTRO OPEN 5PM-8:30PM"])
                == [.between(17 * 60, 20 * 60 + 30)]
        )
        #expect(
            DealTimeParser.timesInText("BISTRO OPEN 5PM-8:30PM")
                == [.between(17 * 60, 20 * 60 + 30)]
        )
    }

    @Test func parsesDottedMeridiemTimeRange() {
        #expect(DealTimeParser.parse(["3 p.m. – 6 p.m."]) == [.between(15 * 60, 18 * 60)])
    }

    @Test func parsesHoursFromPrefixedTimeRange() {
        #expect(DealTimeParser.parse(["2 HRS FROM 12-5PM"]) == [.between(12 * 60, 17 * 60)])
    }

    @Test func parsesBulletWrappedToTimeRange() {
        #expect(DealTimeParser.parse(["• 5PM TO 10PM •"]) == [.between(17 * 60, 22 * 60)])
    }

    @Test func parsesOCRToTokenTimeRange() {
        #expect(DealTimeParser.parse(["5 Tº 6PM"]) == [.between(17 * 60, 18 * 60)])
    }

    @Test func parsesArriveAtForStartTimeAsEveningThroughMidnight() {
        #expect(
            DealTimeParser.parse(["TIME: ARRIVE AT 6:00PM for 6:30PM START"])
                == [.between(18 * 60, 24 * 60)]
        )
    }

    @Test func parsesHyphenContinuedSplitTimeRange() {
        #expect(
            DealTimeParser.parse(["7.30 pm", "-10.30 pm"])
                == [.between(19 * 60 + 30, 22 * 60 + 30)]
        )
    }
}
