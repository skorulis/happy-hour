//Created by Alex Skorulis on 10/7/2026.

import Testing
@testable import DealScraper

struct SingleDateDetectorTests {

    @Test func matchesWeekdayMonthDay() {
        #expect(SingleDateDetector.isMatch(in: ["TUES DEC 16TH"]))
        #expect(SingleDateDetector.isMatch(in: ["TUES DEC I6TH"]))
        #expect(SingleDateDetector.isMatch(in: ["Tuesday 16 December"]))
    }

    @Test func matchesMonthDay() {
        #expect(SingleDateDetector.isMatch(in: ["DEC 16TH"]))
        #expect(SingleDateDetector.isMatch(in: ["June 21"]))
        #expect(SingleDateDetector.isMatch(in: ["16th December"]))
    }

    @Test func matchesNumericDates() {
        #expect(SingleDateDetector.isMatch(in: ["Event on 17/06/2026"]))
        #expect(SingleDateDetector.isMatch(in: ["2026-06-17"]))
    }

    @Test func matchesMumboJumbosPosterLines() {
        #expect(
            SingleDateDetector.isMatch(in: [
                "PIXAR",
                "TUES DEC I6TH",
                "$3.50 TACOS FROM 5PM",
            ])
        )
    }

    @Test func rejectsRecurringWeekdaySchedules() {
        #expect(!SingleDateDetector.isMatch(in: ["EVERY TUES"]))
        #expect(!SingleDateDetector.isMatch(in: ["TUES - THURS 4PM - 6PM"]))
        #expect(!SingleDateDetector.isMatch(in: ["Happy Hour every Friday"]))
        #expect(!SingleDateDetector.isMatch(in: ["MON STEAK NIGHT"]))
        #expect(!SingleDateDetector.isMatch(in: ["WED HALF-PRICE PIZZA"]))
    }

    @Test func rejectsNthWeekdayOfMonthPhrases() {
        #expect(!SingleDateDetector.isMatch(in: ["First Tuesday of each Month"]))
        #expect(!SingleDateDetector.isMatch(in: ["EVERY SECOND FRIDAY OF THE MONTH"]))
    }

    @Test func rejectsEstablishmentDates() {
        #expect(!SingleDateDetector.isMatch(in: ["EST. 1862"]))
    }

    @Test func rejectsDealLinesWithoutCalendarDates() {
        #expect(!SingleDateDetector.isMatch(in: ["$3.50 TACOS FROM 5PM"]))
        #expect(!SingleDateDetector.isMatch(in: ["HAPPY HOUR 4-6PM"]))
    }
}
