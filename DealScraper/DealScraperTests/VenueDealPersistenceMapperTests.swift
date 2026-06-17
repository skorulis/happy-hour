//Created by Alex Skorulis on 17/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct VenueDealPersistenceMapperTests {

    @Test func mapsRawDealToDealAndSchedules() {
        let materials = [
            VenueDealSourceMaterial(
                index: 1,
                dealSourceId: 10,
                url: URL(string: "https://example.com/poster.jpg")!,
                sourceURL: URL(string: "https://example.com/specials")!,
                type: .image,
                pngData: Data()
            ),
        ]

        let payload = DealExtractionPayload(deals: [
            DealExtractionPayload.RawDeal(
                title: "Happy Hour",
                details: ["$8 wines"],
                conditions: ["Dine-in only"],
                days: ["Friday"],
                times: ["4PM - 6PM"],
                sourceIndices: [1]
            ),
        ])

        let mapped = VenueDealPersistenceMapper.map(
            payload: payload,
            venueId: 1,
            materials: materials
        )

        #expect(mapped.count == 1)
        #expect(mapped[0].deal.title == "Happy Hour")
        #expect(mapped[0].deal.details == "$8 wines")
        #expect(mapped[0].deal.conditions == "Dine-in only")
        #expect(mapped[0].deal.imageURL == "https://example.com/poster.jpg")
        #expect(mapped[0].deal.sourceURL == "https://example.com/specials")
        #expect(!mapped[0].schedules.isEmpty)
        #expect(mapped[0].schedules.contains { $0.dayOfWeek == 6 })
    }

    @Test func expandsEveryDayAcrossWeek() {
        let payload = DealExtractionPayload(deals: [
            DealExtractionPayload.RawDeal(
                title: "Daily Special",
                details: ["$5 beers"],
                days: ["every day"],
                times: ["all day"],
                sourceIndices: [1]
            ),
        ])

        let materials = [
            VenueDealSourceMaterial(
                index: 1,
                dealSourceId: 1,
                url: URL(string: "https://example.com/page")!,
                sourceURL: URL(string: "https://example.com/page")!,
                type: .webpage,
                pngData: nil
            ),
        ]

        let mapped = VenueDealPersistenceMapper.map(
            payload: payload,
            venueId: 1,
            materials: materials
        )

        #expect(mapped.count == 1)
        #expect(mapped[0].schedules.count == 7)
    }
}
