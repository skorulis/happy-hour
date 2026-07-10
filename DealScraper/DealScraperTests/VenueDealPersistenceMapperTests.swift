//Created by Alex Skorulis on 17/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct VenueDealPersistenceMapperTests {

    @Test func mapsRawDealToDealAndSchedules() {
        let material = VenueDealSourceMaterial.fixture(
            dealSourceId: 10,
            url: URL(string: "https://example.com/poster.jpg")!,
            sourceURL: URL(string: "https://example.com/specials")!,
            type: .image,
            pngData: Data()
        )
        let payload = DealExtractionPayload(deals: [
            DealExtractionPayload.RawDeal(
                title: "Happy Hour",
                details: ["$8 wines"],
                conditions: ["Dine-in only"],
                days: ["Friday"],
                times: ["4PM - 6PM"]
            ),
        ])

        let mapped = VenueDealPersistenceMapper.map(
            payload: payload,
            venueId: 1,
            material: material
        )

        #expect(mapped.count == 1)
        #expect(mapped[0].deal.title == "Happy Hour")
        #expect(mapped[0].deal.details == "$8 Wines")
        #expect(mapped[0].deal.conditions == "Dine-in only")
        #expect(mapped[0].deal.creativeURL == "https://example.com/poster.jpg")
        #expect(mapped[0].deal.sourceURL == "https://example.com/specials")
        #expect(!mapped[0].schedules.isEmpty)
        #expect(mapped[0].schedules.contains { $0.dayOfWeek == 6 })
    }

    @Test func autoRejectsDealWithSameDayStartAndEndDates() {
        let material = VenueDealSourceMaterial.fixture()
        let payload = DealExtractionPayload(deals: [
            DealExtractionPayload.RawDeal(
                title: "Gift Card Sale",
                details: ["25% off all gift cards"],
                conditions: [],
                days: [],
                times: ["all day"],
                promotionDates: ["14 November 2025"]
            ),
        ])

        let mapped = VenueDealPersistenceMapper.map(
            payload: payload,
            venueId: 1,
            material: material
        )

        #expect(mapped.count == 1)
        #expect(mapped[0].deal.status == .rejected)
    }

    @Test func autoRejectsNthWeekdayOfMonthDeal() {
        let material = VenueDealSourceMaterial.fixture()
        let payload = DealExtractionPayload(deals: [
            DealExtractionPayload.RawDeal(
                title: "Steak Night",
                details: ["$22 steaks", "First Tuesday of each Month"],
                conditions: [],
                days: ["First Tuesday of each Month"],
                times: ["all day"]
            ),
        ])

        let mapped = VenueDealPersistenceMapper.map(
            payload: payload,
            venueId: 1,
            material: material
        )

        #expect(mapped.count == 1)
        #expect(mapped[0].deal.status == .rejected)
    }

    @Test func expandsEveryDayAcrossWeek() {
        let material = VenueDealSourceMaterial.fixture()
        let payload = DealExtractionPayload(deals: [
            DealExtractionPayload.RawDeal(
                title: "Daily Special",
                details: ["$5 beers"],
                days: ["every day"],
                times: ["all day"]
            ),
        ])

        let mapped = VenueDealPersistenceMapper.map(
            payload: payload,
            venueId: 1,
            material: material
        )

        #expect(mapped.count == 1)
        #expect(mapped[0].schedules.count == 7)
    }

    @Test func mapsMultipleSourcesWithCorrectURLs() {
        let firstMaterial = VenueDealSourceMaterial.fixture(
            url: URL(string: "https://example.com/poster-a.jpg")!,
            sourceURL: URL(string: "https://example.com/specials-a")!,
            type: .image,
            pngData: Data(),
        )
        let secondMaterial = VenueDealSourceMaterial.fixture(
            index: 2,
            dealSourceId: 2,
            url: URL(string: "https://example.com/poster-b.jpg")!,
            sourceURL: URL(string: "https://example.com/specials-b")!,
            type: .image,
            pngData: Data(),
        )

        let mapped = VenueDealPersistenceMapper.map(
            sourced: [
                SourcedDealExtraction(
                    material: firstMaterial,
                    deals: [
                        DealExtractionPayload.RawDeal(
                            title: "Deal A",
                            details: ["$5 beers"],
                            days: ["Monday"],
                            times: ["all day"]
                        ),
                    ]
                ),
                SourcedDealExtraction(
                    material: secondMaterial,
                    deals: [
                        DealExtractionPayload.RawDeal(
                            title: "Deal B",
                            details: ["$6 wines"],
                            days: ["Tuesday"],
                            times: ["all day"]
                        ),
                    ]
                ),
            ],
            venueId: 1
        )

        #expect(mapped.count == 2)
        #expect(mapped.contains { $0.deal.title == "Deal A" && $0.deal.creativeURL == "https://example.com/poster-a.jpg" })
        #expect(mapped.contains { $0.deal.title == "Deal B" && $0.deal.creativeURL == "https://example.com/poster-b.jpg" })
        #expect(mapped.contains { $0.deal.title == "Deal A" && $0.deal.sourceURL == "https://example.com/specials-a" })
        #expect(mapped.contains { $0.deal.title == "Deal B" && $0.deal.sourceURL == "https://example.com/specials-b" })
    }

    @Test func mapsPDFCreativeURL() {
        let material = VenueDealSourceMaterial.fixture(
            dealSourceId: 10,
            url: URL(string: "https://example.com/menu.pdf")!,
            sourceURL: URL(string: "https://example.com/specials")!,
            type: .pdf,
            markdown: "Happy Hour"
        )
        let payload = DealExtractionPayload(deals: [
            DealExtractionPayload.RawDeal(
                title: "Happy Hour",
                details: ["$8 wines"],
                days: ["Friday"],
                times: ["4PM - 6PM"]
            ),
        ])

        let mapped = VenueDealPersistenceMapper.map(
            payload: payload,
            venueId: 1,
            material: material
        )

        #expect(mapped.count == 1)
        #expect(mapped[0].deal.creativeURL == "https://example.com/menu.pdf")
    }

    @Test func mapsHappyHourWithSplitEveryWeekdayDays() throws {
        let json = """
        {"deals":[{"conditions":["* SELECTED RANGE OF BEER & WINE"],"times":["4PM-6PM"],"details":["BEERS","$7-"],"days":["EVERY","WEEKDAY"],"title":"HAPPY HOUR"}]}
        """
        let payload = try JSONDecoder().decode(DealExtractionPayload.self, from: Data(json.utf8))
        let material = VenueDealSourceMaterial.fixture()

        let mapped = VenueDealPersistenceMapper.map(
            payload: payload,
            venueId: 1,
            material: material
        )

        #expect(mapped.count == 1)

        let result = try #require(mapped.first)
        #expect(result.deal.title == "Happy Hour")
        #expect(result.deal.details == "Beers\n$7-")
        #expect(result.deal.conditions == "SELECTED RANGE OF BEER & WINE")
        #expect(result.schedules.count == 5)
        #expect(result.schedules.allSatisfy { $0.startMinute == 16 * 60 && $0.endMinute == 18 * 60 })
        #expect(Set(result.schedules.map(\.dayOfWeek)) == Set([2, 3, 4, 5, 6]))
    }

    @Test func mapsGlebeSteakNightFixture() throws {
        let payload = try DealExtractionPayload.fixture(named: "glebe-steak-nights")
        let material = VenueDealSourceMaterial.fixture()

        let mapped = VenueDealPersistenceMapper.map(
            payload: payload,
            venueId: 42,
            material: material
        )

        #expect(mapped.count == 1)

        let result = try #require(mapped.first)
        #expect(result.deal.venueId == 42)
        #expect(result.deal.title == "$22 Steak Night")
        #expect(result.deal.details == "Raise\nThe\nSteaks")
        #expect(result.deal.conditions == "only available with bar service in our public bar, beer garden and nude")

        #expect(result.schedules.count == 1)
        let schedule = try #require(result.schedules.first)
        #expect(schedule.dayOfWeek == 2)
        #expect(schedule.startMinute == 0)
        #expect(schedule.endMinute == 1_440)
    }

    @Test func adjustsDinnerDealStartFromMidnightTo5PM() {
        let material = VenueDealSourceMaterial.fixture()
        let payload = DealExtractionPayload(deals: [
            DealExtractionPayload.RawDeal(
                title: "Dinner Special",
                details: ["$25 mains"],
                days: ["Friday"],
                times: ["till 10pm"]
            ),
        ])

        let mapped = VenueDealPersistenceMapper.map(
            payload: payload,
            venueId: 1,
            material: material
        )

        #expect(mapped.count == 1)
        #expect(mapped[0].schedules.count == 1)
        #expect(mapped[0].schedules[0].startMinute == 17 * 60)
        #expect(mapped[0].schedules[0].endMinute == 22 * 60)
    }

    @Test func adjustsEveningDealStartFromMidnightTo5PM() {
        let material = VenueDealSourceMaterial.fixture()
        let payload = DealExtractionPayload(deals: [
            DealExtractionPayload.RawDeal(
                title: "Evening Special",
                details: ["$25 mains"],
                days: ["Friday"],
                times: ["till 10pm"]
            ),
        ])

        let mapped = VenueDealPersistenceMapper.map(
            payload: payload,
            venueId: 1,
            material: material
        )

        #expect(mapped.count == 1)
        #expect(mapped[0].schedules[0].startMinute == 17 * 60)
        #expect(mapped[0].schedules[0].endMinute == 22 * 60)
    }

    @Test func adjustsLunchDealFromMidnightToMidnightTo12PM2PM() {
        let material = VenueDealSourceMaterial.fixture()
        let payload = DealExtractionPayload(deals: [
            DealExtractionPayload.RawDeal(
                title: "Lunch Special",
                details: ["$15 burgers"],
                days: ["Monday"],
                times: ["all day"]
            ),
        ])

        let mapped = VenueDealPersistenceMapper.map(
            payload: payload,
            venueId: 1,
            material: material
        )

        #expect(mapped.count == 1)
        #expect(mapped[0].schedules[0].startMinute == 12 * 60)
        #expect(mapped[0].schedules[0].endMinute == 14 * 60)
    }

    @Test func doesNotAdjustLunchDealWithExplicitTimes() {
        let material = VenueDealSourceMaterial.fixture()
        let payload = DealExtractionPayload(deals: [
            DealExtractionPayload.RawDeal(
                title: "Lunch Special",
                details: ["$15 burgers"],
                days: ["Monday"],
                times: ["till 10pm"]
            ),
        ])

        let mapped = VenueDealPersistenceMapper.map(
            payload: payload,
            venueId: 1,
            material: material
        )

        #expect(mapped.count == 1)
        #expect(mapped[0].schedules[0].startMinute == 0)
        #expect(mapped[0].schedules[0].endMinute == 22 * 60)
    }

    @Test func doesNotAdjustDinnerStartWhenLunchIsMentioned() {
        let material = VenueDealSourceMaterial.fixture()
        let payload = DealExtractionPayload(deals: [
            DealExtractionPayload.RawDeal(
                title: "Lunch and Dinner",
                details: ["Available all evening"],
                days: ["Friday"],
                times: ["till 10pm"]
            ),
        ])

        let mapped = VenueDealPersistenceMapper.map(
            payload: payload,
            venueId: 1,
            material: material
        )

        #expect(mapped.count == 1)
        #expect(mapped[0].schedules[0].startMinute == 0)
        #expect(mapped[0].schedules[0].endMinute == 22 * 60)
    }

    @Test func doesNotAdjustNonDinnerDealStartFromMidnight() {
        let material = VenueDealSourceMaterial.fixture()
        let payload = DealExtractionPayload(deals: [
            DealExtractionPayload.RawDeal(
                title: "Happy Hour",
                details: ["$8 wines"],
                days: ["Friday"],
                times: ["till 10pm"]
            ),
        ])

        let mapped = VenueDealPersistenceMapper.map(
            payload: payload,
            venueId: 1,
            material: material
        )

        #expect(mapped.count == 1)
        #expect(mapped[0].schedules[0].startMinute == 0)
        #expect(mapped[0].schedules[0].endMinute == 22 * 60)
    }

    @Test func mapsCalendarOnlyDealFromPromotionDates() throws {
        let material = VenueDealSourceMaterial.fixture()
        let payload = DealExtractionPayload(deals: [
            DealExtractionPayload.RawDeal(
                title: "Gift Card Sale – 25% Off",
                details: ["25% off all gift cards"],
                conditions: ["Enter code BLKFDAY at checkout to receive 25% off."],
                days: [],
                times: ["all day"],
                promotionDates: ["Friday, 14 November – Monday, 1 December 2025"]
            ),
        ])

        let mapped = VenueDealPersistenceMapper.map(
            payload: payload,
            venueId: 1,
            material: material
        )

        #expect(mapped.count == 1)

        let result = try #require(mapped.first)
        #expect(result.schedules.isEmpty)
        let start = try #require(result.deal.startDate)
        let end = try #require(result.deal.endDate)
        let calendar = Calendar.current
        #expect(calendar.component(.year, from: start) == 2025)
        #expect(calendar.component(.month, from: start) == 11)
        #expect(calendar.component(.day, from: start) == 14)
        #expect(calendar.component(.year, from: end) == 2025)
        #expect(calendar.component(.month, from: end) == 12)
        #expect(calendar.component(.day, from: end) == 1)
        #expect(result.deal.status == .new)
    }
}
