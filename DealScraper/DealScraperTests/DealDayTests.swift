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
        #expect(DealDay.parseAll(in: "TUES - THURS 4PM - 6PM / FRI 3PM - 5PM") == [.tuesday, .thursday, .friday])
    }

    @Test func returnsNilForUnparseableInput() {
        #expect(DealDay.parse("") == nil)
        #expect(DealDay.parse("notaday") == nil)
    }
}
