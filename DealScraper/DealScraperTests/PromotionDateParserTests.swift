//Created by Alex Skorulis on 7/7/2026.

import Foundation
import Testing
@testable import DealScraper

struct PromotionDateParserTests {

    @Test func parsesDateRangeWithYearOnEnd() throws {
        let result = PromotionDateParser.parse([
            "Friday, 14 November – Monday, 1 December 2025",
        ])

        let start = try #require(result.start)
        let end = try #require(result.end)
        #expect(calendar.component(.year, from: start) == 2025)
        #expect(calendar.component(.month, from: start) == 11)
        #expect(calendar.component(.day, from: start) == 14)
        #expect(calendar.component(.year, from: end) == 2025)
        #expect(calendar.component(.month, from: end) == 12)
        #expect(calendar.component(.day, from: end) == 1)
    }

    @Test func parsesSingleDate() throws {
        let result = PromotionDateParser.parse(["14 November 2025"])

        let start = try #require(result.start)
        let end = try #require(result.end)
        #expect(start == end)
        #expect(calendar.component(.month, from: start) == 11)
        #expect(calendar.component(.day, from: start) == 14)
    }

    @Test func parsesUntilPrefix() throws {
        let result = PromotionDateParser.parse(["until 31 December 2025"])

        #expect(result.start == nil)
        let end = try #require(result.end)
        #expect(calendar.component(.month, from: end) == 12)
        #expect(calendar.component(.day, from: end) == 31)
        #expect(calendar.component(.year, from: end) == 2025)
    }

    @Test func parsesFromPrefix() throws {
        let result = PromotionDateParser.parse(["from 14 November 2025"])

        let start = try #require(result.start)
        #expect(result.end == nil)
        #expect(calendar.component(.month, from: start) == 11)
        #expect(calendar.component(.day, from: start) == 14)
    }

    @Test func parsesFromThroughEndOfMonthRange() throws {
        let result = PromotionDateParser.parse(["from Monday 18 May through to the end of June."])

        let start = try #require(result.start)
        let end = try #require(result.end)
        #expect(calendar.component(.month, from: start) == 5)
        #expect(calendar.component(.day, from: start) == 18)
        #expect(calendar.component(.month, from: end) == 6)
        #expect(calendar.component(.day, from: end) == 30)
        #expect(calendar.component(.year, from: start) == calendar.component(.year, from: end))
    }

    @Test func returnsNilForUnparseableText() {
        let result = PromotionDateParser.parse(["Black Friday only"])
        #expect(result.start == nil)
        #expect(result.end == nil)
    }

    @Test func mergesMultipleLinesToWidestRange() throws {
        let result = PromotionDateParser.parse([
            "from 1 November 2025",
            "until 31 December 2025",
        ])

        let start = try #require(result.start)
        let end = try #require(result.end)
        #expect(calendar.component(.month, from: start) == 11)
        #expect(calendar.component(.day, from: start) == 1)
        #expect(calendar.component(.month, from: end) == 12)
        #expect(calendar.component(.day, from: end) == 31)
    }

    @Test func returnsNilForNilInput() {
        let result = PromotionDateParser.parse(nil)
        #expect(result.start == nil)
        #expect(result.end == nil)
    }

    private var calendar: Calendar {
        Calendar.current
    }
}
