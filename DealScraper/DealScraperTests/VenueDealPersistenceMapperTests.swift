//Created by Alex Skorulis on 17/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct VenueDealPersistenceMapperTests {

    @Test func mapsRawDealToDealAndSchedules() {
        let material = VenueDealSourceMaterial(
            index: 1,
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
        #expect(mapped[0].deal.details == "$8 wines")
        #expect(mapped[0].deal.conditions == "Dine-in only")
        #expect(mapped[0].deal.imageURL == "https://example.com/poster.jpg")
        #expect(mapped[0].deal.sourceURL == "https://example.com/specials")
        #expect(!mapped[0].schedules.isEmpty)
        #expect(mapped[0].schedules.contains { $0.dayOfWeek == 6 })
    }

    @Test func expandsEveryDayAcrossWeek() {
        let material = VenueDealSourceMaterial(
            index: 1,
            dealSourceId: 1,
            url: URL(string: "https://example.com/page")!,
            sourceURL: URL(string: "https://example.com/page")!,
            type: .webpage,
            pngData: nil
        )
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
        let firstMaterial = VenueDealSourceMaterial(
            index: 1,
            dealSourceId: 1,
            url: URL(string: "https://example.com/poster-a.jpg")!,
            sourceURL: URL(string: "https://example.com/specials-a")!,
            type: .image,
            pngData: Data()
        )
        let secondMaterial = VenueDealSourceMaterial(
            index: 2,
            dealSourceId: 2,
            url: URL(string: "https://example.com/poster-b.jpg")!,
            sourceURL: URL(string: "https://example.com/specials-b")!,
            type: .image,
            pngData: Data()
        )

        let mapped = VenueDealPersistenceMapper.map(
            sourced: [
                SourcedDealExtraction(
                    material: firstMaterial,
                    deals: [
                        DealExtractionPayload.RawDeal(
                            title: "Deal A",
                            details: ["$5"],
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
                            details: ["$6"],
                            days: ["Tuesday"],
                            times: ["all day"]
                        ),
                    ]
                ),
            ],
            venueId: 1
        )

        #expect(mapped.count == 2)
        #expect(mapped.contains { $0.deal.title == "Deal A" && $0.deal.imageURL == "https://example.com/poster-a.jpg" })
        #expect(mapped.contains { $0.deal.title == "Deal B" && $0.deal.imageURL == "https://example.com/poster-b.jpg" })
        #expect(mapped.contains { $0.deal.title == "Deal A" && $0.deal.sourceURL == "https://example.com/specials-a" })
        #expect(mapped.contains { $0.deal.title == "Deal B" && $0.deal.sourceURL == "https://example.com/specials-b" })
    }
}
