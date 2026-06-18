//Created by Alex Skorulis on 18/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct DealCondenserTests {

    private let condenser = DealCondenser()

    @Test func mergesPartialImageDealWithFullWebpageDeal() {
        let imageDeal = makeDeal(
            title: nil,
            details: "$8 wines",
            imageURL: "https://example.com/poster.jpg",
            sourceURL: "https://example.com/specials",
            schedules: [schedule(day: 3, start: 0, end: 1_440)]
        )
        let webpageDeal = makeDeal(
            title: "Happy Hour",
            details: "$8 wines\n$8 schooners",
            sourceURL: "https://example.com/menu",
            schedules: [schedule(day: 3, start: 960, end: 1_080)]
        )

        let result = condenser.condense([imageDeal, webpageDeal])

        #expect(result.count == 1)
        let merged = result[0]
        #expect(merged.deal.title == "Happy Hour")
        #expect(merged.deal.imageURL == "https://example.com/poster.jpg")
        #expect(merged.deal.sourceURL == "https://example.com/menu")
        #expect(merged.deal.details?.contains("$8 wines") == true)
        #expect(merged.deal.details?.contains("$8 schooners") == true)
        #expect(merged.schedules.count == 2)
    }

    @Test func leavesDistinctDealsUnchanged() {
        let dealA = makeDeal(
            title: "Deal A",
            details: "$5",
            schedules: [schedule(day: 2, start: 0, end: 1_440)]
        )
        let dealB = makeDeal(
            title: "Deal B",
            details: "$6",
            schedules: [schedule(day: 3, start: 0, end: 1_440)]
        )

        let result = condenser.condense([dealA, dealB])

        #expect(result.count == 2)
    }

    @Test func mergesDealsWithExactSharedDetailLine() {
        let first = makeDeal(
            title: "Happy Hour",
            details: "$8 wines",
            sourceURL: "https://example.com/a",
            schedules: [schedule(day: 3, start: 960, end: 1_080)]
        )
        let second = makeDeal(
            title: nil,
            details: "$8 wines",
            sourceURL: "https://example.com/b",
            schedules: [schedule(day: 5, start: 960, end: 1_080)]
        )

        let result = condenser.condense([first, second])

        #expect(result.count == 1)
        #expect(result[0].deal.title == "Happy Hour")
        #expect(result[0].schedules.contains { $0.dayOfWeek == 3 })
        #expect(result[0].schedules.contains { $0.dayOfWeek == 5 })
    }

    @Test func mergesDealsWithMinorTypo() {
        let first = makeDeal(
            title: "Happy Hour",
            details: "$8 schooners",
            schedules: [schedule(day: 3, start: 960, end: 1_080)]
        )
        let second = makeDeal(
            title: "Happy Hour",
            details: "$8 schooner",
            schedules: [schedule(day: 3, start: 960, end: 1_080)]
        )

        let result = condenser.condense([first, second])

        #expect(result.count == 1)
    }

    @Test func unionsSchedulesFromMatchingSources() {
        let tuesday = makeDeal(
            title: "Happy Hour",
            details: "$8 wines",
            schedules: [schedule(day: 3, start: 960, end: 1_080)]
        )
        let thursday = makeDeal(
            title: "Happy Hour",
            details: "$8 wines",
            schedules: [schedule(day: 5, start: 960, end: 1_080)]
        )

        let result = condenser.condense([tuesday, thursday])

        #expect(result.count == 1)
        #expect(result[0].schedules.count == 2)
        #expect(result[0].schedules.contains { $0.dayOfWeek == 3 })
        #expect(result[0].schedules.contains { $0.dayOfWeek == 5 })
    }

    @Test func doesNotMergeConflictingSchedulesWithWeakText() {
        let early = makeDeal(
            title: "Early Happy Hour",
            details: "$5 snacks",
            schedules: [schedule(day: 3, start: 960, end: 1_080)]
        )
        let late = makeDeal(
            title: "Late Night Special",
            details: "$6 cocktails",
            schedules: [schedule(day: 3, start: 1_200, end: 1_320)]
        )

        let result = condenser.condense([early, late])

        #expect(result.count == 2)
    }

    private func makeDeal(
        title: String? = nil,
        details: String? = nil,
        conditions: String? = nil,
        imageURL: String? = nil,
        sourceURL: String? = nil,
        schedules: [DealSchedule] = []
    ) -> DealWithSchedules {
        let deal = Deal(
            venueId: 1,
            title: title,
            imageURL: imageURL,
            sourceURL: sourceURL,
            details: details,
            conditions: conditions
        )
        return DealWithSchedules(deal: deal, schedules: schedules)
    }

    private func schedule(day: Int, start: Int, end: Int) -> DealSchedule {
        DealSchedule(dealId: 0, dayOfWeek: day, startMinute: start, endMinute: end)
    }
}
