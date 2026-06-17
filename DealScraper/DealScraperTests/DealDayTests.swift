//Created by Alexander Skorulis on 14/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct DealDayTests {

    @Test func parsesFullDayNames() {
        #expect(DealDay.parse("monday") == .monday)
        #expect(DealDay.parse("Tuesday") == .tuesday)
        #expect(DealDay.parse("  SUNDAY  ") == .sunday)
    }

    @Test func parsesAbbreviations() {
        #expect(DealDay.parse("tues") == .tuesday)
        #expect(DealDay.parse("thurs") == .thursday)
        #expect(DealDay.parse("sun") == .sunday)
        #expect(DealDay.parse("mon") == .monday)
    }

    @Test func parseAllFindsDaysInVerbatimLines() {
        #expect(DealDay.parseAll(in: "EVERY TUES") == [.tuesday])
        #expect(DealDay.parseAll(in: "CHEESEBURGER TUESDAYS") == [.tuesday])
        #expect(DealDay.parseAll(in: "TUES - THURS 4PM - 6PM / FRI 3PM - 5PM") == [.tuesday, .wednesday, .thursday, .friday])
    }

    @Test func parseAllExpandsDayRanges() {
        #expect(DealDay.parseAll(in: "MONDAY - FRIDAY") == [.monday, .tuesday, .wednesday, .thursday, .friday])
        #expect(DealDay.parseAll(in: "MONDAY to FRIDAY") == [.monday, .tuesday, .wednesday, .thursday, .friday])
        #expect(DealDay.parseAll(in: "MON - FRI") == [.monday, .tuesday, .wednesday, .thursday, .friday])
        #expect(DealDay.parseAll(in: "MON-FRI") == [.monday, .tuesday, .wednesday, .thursday, .friday])
        #expect(DealDay.parseAll(in: "FRI - MON") == [.monday, .friday, .saturday, .sunday])
    }

    @Test func returnsNilForUnparseableInput() {
        #expect(DealDay.parse("") == nil)
        #expect(DealDay.parse("notaday") == nil)
    }

    @Test func isMentionedFindsFullNamesAndAbbreviations() {
        #expect(DealDay.isMentioned(in: "Happy Hour every Friday"))
        #expect(DealDay.isMentioned(in: "TUES - THURS 4PM - 6PM"))
        #expect(!DealDay.isMentioned(in: "Special offers on selected drinks"))
        #expect(!DealDay.isMentioned(in: ""))
    }
}
