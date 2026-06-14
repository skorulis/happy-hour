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

    @Test func returnsNilForUnparseableInput() {
        #expect(DealDay.parse("") == nil)
        #expect(DealDay.parse("notaday") == nil)
    }
}
