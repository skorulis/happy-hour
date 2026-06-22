//Created by Alex Skorulis on 18/6/2026.

import Foundation
import Testing
@testable import DealScraper

@Suite(.serialized)
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

    @Test func doesNotMergeDealsWithSharedDetailLineOnDifferentDays() {
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

        #expect(result.count == 2)
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

    @Test func leavesMatchingDealsOnDifferentDaysSeparate() {
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

        #expect(result.count == 2)
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

    @Test func condensesGlebeFixtures() throws {
        let whatsOnMaterial = VenueDealSourceMaterial.fixture(
            sourceURL: URL(string: "https://example.com/whats-on")!,
            type: .webpage
        )
        let steakNightsMaterial = VenueDealSourceMaterial.fixture(
            index: 2,
            dealSourceId: 2,
            url: URL(string: "https://example.com/steak-nights.jpg")!,
            sourceURL: URL(string: "https://example.com/steak-nights.jpg")!,
            type: .image,
            pngData: Data()
        )

        let whatsOnMapped = try mappedDeals(fixture: "glebe-whats-on", material: whatsOnMaterial)
        let steakNightsMapped = try mappedDeals(fixture: "glebe-steak-nights", material: steakNightsMaterial)

        let mapped = whatsOnMapped + steakNightsMapped
        #expect(mapped.count == 11)

        let result = condenser.condense(mapped)

        #expect(result.count == 10)
        #expect(result.filter { $0.deal.title == "$22 STEAK NIGHT" }.count == 1)

        let steakNight = try #require(result.first { $0.deal.title == "$22 STEAK NIGHT" })
        #expect(steakNight.deal.details == "Raise\nthe\nSteaks")
        #expect(steakNight.deal.conditions?.contains("Conditions Apply") == true)
        #expect(steakNight.deal.conditions?.contains("only available with bar service in our public bar, beer garden and nude") == true)
        #expect(steakNight.deal.imageURL == "https://example.com/steak-nights.jpg")
        #expect(steakNight.schedules.count == 1)
        #expect(steakNight.schedules[0].dayOfWeek == 2)
        #expect(steakNight.schedules[0].startMinute == 0)
        #expect(steakNight.schedules[0].endMinute == 1_440)

        let expectedTitles: Set<String> = [
            "$15 LUNCH SPECIALS",
            "$22 STEAK NIGHT",
            "2-4-1 MEAL DEAL",
            "TRIVIA NIGHT",
            "PICK THE JOKER",
            "$18 BURGERS",
            "$13 APEROL SPRITZ & $15 ESPRESSO MARTINIS",
            "SUNDAY ROAST $35",
            "PETS WELCOME",
            "MEMBERS HAPPY HOUR",
        ]
        let resultTitles = Set(result.compactMap(\.deal.title))
        #expect(resultTitles == expectedTitles)
    }

    private func mappedDeals(
        fixture name: String,
        material: VenueDealSourceMaterial,
        venueId: Int64 = 42
    ) throws -> [DealWithSchedules] {
        let payload = try DealExtractionPayload.fixture(named: name)
        return VenueDealPersistenceMapper.map(
            payload: payload,
            venueId: venueId,
            material: material
        )
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

@Suite(.serialized)
struct DealCondenserShouldMergeTests {

    private let condenser = DealCondenser()

    @Test func mergesWhenTitlesMatchExactly() {
        let webpage = makeDeal(
            title: "$22 STEAK NIGHT",
            conditions: "Conditions Apply",
            schedules: [schedule(day: 2, start: 0, end: 1_440)]
        )
        let poster = makeDeal(
            title: "$22 STEAK NIGHT",
            details: "Raise\nthe\nSteaks",
            conditions: "*only available with bar service",
            schedules: [schedule(day: 2, start: 0, end: 1_440)]
        )

        #expect(condenser.shouldMerge(webpage, poster))
    }

    @Test func doesNotMergeWhenDetailsMatchOnDifferentDays() {
        let first = makeDeal(
            title: "Happy Hour",
            details: "$8 wines",
            schedules: [schedule(day: 3, start: 960, end: 1_080)]
        )
        let second = makeDeal(
            title: nil,
            details: "$8 wines",
            schedules: [schedule(day: 5, start: 960, end: 1_080)]
        )

        #expect(!condenser.shouldMerge(first, second))
    }

    @Test func doesNotMergeWhenOnlySharedConditionsMatch() {
        let lunch = makeDeal(
            title: "$15 LUNCH SPECIALS",
            conditions: "Conditions Apply",
            schedules: [schedule(day: 2, start: 0, end: 1_440)]
        )
        let steak = makeDeal(
            title: "$22 STEAK NIGHT",
            conditions: "Conditions Apply",
            schedules: [schedule(day: 2, start: 0, end: 1_440)]
        )

        #expect(!condenser.shouldMerge(lunch, steak))
    }

    @Test func doesNotMergeUnrelatedDealsOnDifferentDays() {
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

        #expect(!condenser.shouldMerge(dealA, dealB))
    }

    @Test func mergesWhenShorterDealTextIsContainedInLongerDeal() {
        let imageDeal = makeDeal(
            details: "$8 wines",
            schedules: [schedule(day: 3, start: 0, end: 1_440)]
        )
        let webpageDeal = makeDeal(
            title: "Happy Hour",
            details: "$8 wines\n$8 schooners",
            schedules: [schedule(day: 3, start: 960, end: 1_080)]
        )

        #expect(condenser.shouldMerge(imageDeal, webpageDeal))
    }

    @Test func mergesWhenTextIsSimilarAndTokensOverlap() {
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

        #expect(condenser.shouldMerge(first, second))
    }

    @Test func doesNotMergeWhenTextMatchesOnDifferentDays() {
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

        #expect(!condenser.shouldMerge(tuesday, thursday))
    }

    @Test func doesNotMergeWhenSameDaySchedulesConflictWithWeakText() {
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

        #expect(!condenser.shouldMerge(early, late))
    }

    @Test func mergesDespiteConflictingTimesWhenTitleMatchesExactly() {
        let early = makeDeal(
            title: "Happy Hour",
            details: "$8 wines",
            schedules: [schedule(day: 3, start: 960, end: 1_080)]
        )
        let late = makeDeal(
            title: "Happy Hour",
            details: "$8 beers",
            schedules: [schedule(day: 3, start: 1_200, end: 1_320)]
        )

        #expect(condenser.shouldMerge(early, late))
    }

    @Test func doesNotMergeWhenSchedulesOverlapButTextHasNoTokenOverlap() {
        let lunch = makeDeal(
            title: "$15 LUNCH SPECIALS",
            schedules: [schedule(day: 2, start: 0, end: 1_440)]
        )
        let trivia = makeDeal(
            title: "TRIVIA NIGHT",
            details: "+$20 SCHNITZEL",
            schedules: [schedule(day: 2, start: 0, end: 1_440)]
        )

        #expect(!condenser.shouldMerge(lunch, trivia))
    }

    @Test func doesNotMergeWhenTextSimilarityIsBelowThreshold() {
        let strict = DealCondenser(matchThreshold: 0.95)
        let first = makeDeal(
            title: "Trivia Night",
            details: "$20 schnitzel",
            schedules: [schedule(day: 4, start: 0, end: 1_440)]
        )
        let second = makeDeal(
            title: "Pick the Joker",
            details: "$28 curry and a can",
            schedules: [schedule(day: 4, start: 0, end: 1_440)]
        )

        #expect(!strict.shouldMerge(first, second))
    }

    @Test func doesNotMergeWhenTokenOnlyOverlapsAcrossTitleAndDetail() {
        let burgers = makeDeal(
            title: "$18 BURGERS",
            details: "Members Meat tray & Manicure draw at 6pm",
            schedules: [schedule(day: 6, start: 0, end: 1_440)]
        )
        let membersHour = makeDeal(
            title: "MEMBERS HAPPY HOUR",
            details: "Beer & wine from $6",
            schedules: [schedule(day: 6, start: 960, end: 1_080)]
        )

        #expect(!condenser.shouldMerge(burgers, membersHour))
    }

    @Test func glebeBurgersAndMembersHappyHourShouldNotMerge() throws {
        let material = VenueDealSourceMaterial.fixture(
            sourceURL: URL(string: "https://example.com/whats-on")!,
            type: .webpage
        )
        let mapped = try mappedDeals(fixture: "glebe-whats-on", material: material)
        let burgers = try #require(mapped.first { $0.deal.title == "$18 BURGERS" })
        let members = try #require(mapped.first { $0.deal.title == "MEMBERS HAPPY HOUR" })

        #expect(!condenser.shouldMerge(burgers, members))
    }

    @Test func glebeWhatsOnAloneCondensesToTenDeals() throws {
        let material = VenueDealSourceMaterial.fixture(
            sourceURL: URL(string: "https://example.com/whats-on")!,
            type: .webpage
        )
        let mapped = try mappedDeals(fixture: "glebe-whats-on", material: material)
        #expect(mapped.count == 10)

        let result = condenser.condense(mapped)
        #expect(result.count == 10)
    }

    private func mappedDeals(
        fixture name: String,
        material: VenueDealSourceMaterial,
        venueId: Int64 = 42
    ) throws -> [DealWithSchedules] {
        let payload = try DealExtractionPayload.fixture(named: name)
        return VenueDealPersistenceMapper.map(
            payload: payload,
            venueId: venueId,
            material: material
        )
    }

    private func makeDeal(
        title: String? = nil,
        details: String? = nil,
        conditions: String? = nil,
        schedules: [DealSchedule] = []
    ) -> DealWithSchedules {
        let deal = Deal(
            venueId: 1,
            title: title,
            details: details,
            conditions: conditions
        )
        return DealWithSchedules(deal: deal, schedules: schedules)
    }

    private func schedule(day: Int, start: Int, end: Int) -> DealSchedule {
        DealSchedule(dealId: 0, dayOfWeek: day, startMinute: start, endMinute: end)
    }
}
