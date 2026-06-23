//Created by Alex Skorulis on 23/6/2026.

import Foundation
import Testing
@testable import DealScraper

@Suite(.serialized)
struct KeywordDealCondenserTests {

    private let condenser = KeywordDealCondenser()

    @Test func mergesDealsWithSameKeywordAndDaysKeepingRicherText() {
        let sparse = makeDeal(
            title: nil,
            details: "$8 wines",
            creativeURL: "https://example.com/poster.jpg",
            schedules: [schedule(day: 3, start: 960, end: 1_080)]
        )
        let detailed = makeDeal(
            title: "Happy Hour",
            details: "$8 wines\n$8 schooners",
            schedules: [schedule(day: 3, start: 960, end: 1_080)]
        )

        let result = condenser.condense([sparse, detailed])

        #expect(result.count == 1)
        #expect(result[0].deal.title == "Happy Hour")
        #expect(result[0].deal.details == "$8 wines\n$8 schooners")
        #expect(result[0].deal.creativeURL == "https://example.com/poster.jpg")
    }

    @Test func doesNotMergeDealsWithDifferentKeywordsOnSameDay() {
        let lunch = makeDeal(
            title: "$15 LUNCH SPECIALS",
            schedules: [schedule(day: 2, start: 0, end: 1_440)]
        )
        let steak = makeDeal(
            title: "$22 STEAK NIGHT",
            schedules: [schedule(day: 2, start: 0, end: 1_440)]
        )

        let result = condenser.condense([lunch, steak])

        #expect(result.count == 2)
    }

    @Test func doesNotMergeDealsWithSameKeywordOnDifferentDays() {
        let wednesday = makeDeal(
            details: "$8 wines",
            schedules: [schedule(day: 3, start: 960, end: 1_080)]
        )
        let friday = makeDeal(
            details: "$8 wines",
            schedules: [schedule(day: 5, start: 960, end: 1_080)]
        )

        let result = condenser.condense([wednesday, friday])

        #expect(result.count == 2)
    }

    @Test func doesNotMergeDealsWithNoProductKeywords() {
        let first = makeDeal(
            title: "Deal A",
            details: "$5",
            schedules: [schedule(day: 2, start: 0, end: 1_440)]
        )
        let second = makeDeal(
            title: "Deal B",
            details: "$6",
            schedules: [schedule(day: 2, start: 0, end: 1_440)]
        )

        #expect(!condenser.shouldMerge(first, second))
        #expect(condenser.condense([first, second]).count == 2)
    }

    @Test func mergesSchedulesFromBothDeals() {
        let early = makeDeal(
            details: "$8 wines",
            schedules: [schedule(day: 3, start: 960, end: 1_020)]
        )
        let late = makeDeal(
            title: "Happy Hour",
            details: "$8 wines\n$8 house wines",
            schedules: [schedule(day: 3, start: 1_020, end: 1_080)]
        )

        let result = condenser.condense([early, late])

        #expect(result.count == 1)
        #expect(result[0].schedules.count == 2)
    }
    
    @Test func testBrewdogMerge() {
        let first = makeDeal(
            title: "Wings Wednesday",
            details: """
                Load up on bottomless chicken or cauliflower wings. Buffalo and Korean faves plus FIVE NEW FLAVOURS.
                Grab your mates for FREE pool & AYCE wings every Wednesday.
                Dare to brave our spicy wing challenge?
                Eat a plate of spicy wings in under 10 mins to make our Wall of Fame.
                $30pp
                """,
            schedules: [schedule(day: 3, start: 960, end: 1_020)]
        )
        
        let second = makeDeal(
            title: "WINGS WEDNESDAY",
            schedules: [schedule(day: 3, start: 960, end: 1_020)]
        )
        
        let result = condenser.condense([second, first])
        #expect(result.count == 1)
        #expect(result[0].deal.title == "Wings Wednesday")
        #expect(result[0].deal.details?.isEmpty == false)
        
    }

    private func makeDeal(
        title: String? = nil,
        details: String? = nil,
        conditions: String? = nil,
        creativeURL: String? = nil,
        schedules: [DealSchedule] = []
    ) -> DealWithSchedules {
        let deal = Deal(
            venueId: 1,
            title: title,
            creativeURL: creativeURL,
            details: details,
            conditions: conditions
        )
        return DealWithSchedules(deal: deal, schedules: schedules)
    }

    private func schedule(day: Int, start: Int, end: Int) -> DealSchedule {
        DealSchedule(dealId: 0, dayOfWeek: day, startMinute: start, endMinute: end)
    }
}
