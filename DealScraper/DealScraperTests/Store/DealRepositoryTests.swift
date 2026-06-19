//Created by Alex Skorulis on 17/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct DealRepositoryTests {

    @Test func replaceAllInsertsDealsAndSchedules() throws {
        let store = SQLStore.inMemory()
        let venueRepository = VenueRepository(store: store)
        let dealRepository = DealRepository(store: store)

        try venueRepository.upsert(Venue(
            googleMapId: "places/test",
            name: "Test Pub",
            lat: 0,
            lng: 0,
            json: "{}"
        ))

        let venueId = try #require(try venueRepository.find(googleMapId: "places/test")?.id)

        let deal = Deal(
            venueId: venueId,
            title: "Happy Hour",
            details: "$8 wines",
            conditions: "Dine-in only"
        )
        let schedules = [
            DealSchedule(dealId: 0, dayOfWeek: 6, startMinute: 960, endMinute: 1_080),
        ]

        let count = try dealRepository.replaceAll(
            venueId: venueId,
            deals: [DealWithSchedules(deal: deal, schedules: schedules)]
        )
        #expect(count == 1)

        let found = try dealRepository.find(venueId: venueId)
        #expect(found.count == 1)
        #expect(found[0].deal.title == "Happy Hour")
        #expect(found[0].deal.details == "$8 wines")
        #expect(found[0].schedules.count == 1)
        #expect(found[0].schedules[0].dayOfWeek == 6)
    }

    @Test func replaceAllReplacesExistingDeals() throws {
        let store = SQLStore.inMemory()
        let venueRepository = VenueRepository(store: store)
        let dealRepository = DealRepository(store: store)

        try venueRepository.upsert(Venue(
            googleMapId: "places/test",
            name: "Test Pub",
            lat: 0,
            lng: 0,
            json: "{}"
        ))

        let venueId = try #require(try venueRepository.find(googleMapId: "places/test")?.id)

        _ = try dealRepository.replaceAll(
            venueId: venueId,
            deals: [
                DealWithSchedules(
                    deal: Deal(venueId: venueId, title: "Old Deal"),
                    schedules: []
                ),
            ]
        )

        _ = try dealRepository.replaceAll(
            venueId: venueId,
            deals: [
                DealWithSchedules(
                    deal: Deal(venueId: venueId, title: "New Deal"),
                    schedules: []
                ),
            ]
        )

        let found = try dealRepository.find(venueId: venueId)
        #expect(found.count == 1)
        #expect(found[0].deal.title == "New Deal")
    }

    @Test func deleteAllRemovesDealsForVenue() throws {
        let store = SQLStore.inMemory()
        let venueRepository = VenueRepository(store: store)
        let dealRepository = DealRepository(store: store)

        try venueRepository.upsert(Venue(
            googleMapId: "places/test",
            name: "Test Pub",
            lat: 0,
            lng: 0,
            json: "{}"
        ))

        let venueId = try #require(try venueRepository.find(googleMapId: "places/test")?.id)

        _ = try dealRepository.replaceAll(
            venueId: venueId,
            deals: [
                DealWithSchedules(
                    deal: Deal(venueId: venueId, title: "Happy Hour"),
                    schedules: [
                        DealSchedule(dealId: 0, dayOfWeek: 6, startMinute: 960, endMinute: 1_080),
                    ]
                ),
            ]
        )

        let deleted = try dealRepository.deleteAll(venueId: venueId)
        #expect(deleted == 1)
        #expect(try dealRepository.find(venueId: venueId).isEmpty)
    }

    @Test func updateStatusPersistsDealStatus() throws {
        let store = SQLStore.inMemory()
        let venueRepository = VenueRepository(store: store)
        let dealRepository = DealRepository(store: store)

        try venueRepository.upsert(Venue(
            googleMapId: "places/test",
            name: "Test Pub",
            lat: 0,
            lng: 0,
            json: "{}"
        ))

        let venueId = try #require(try venueRepository.find(googleMapId: "places/test")?.id)

        _ = try dealRepository.replaceAll(
            venueId: venueId,
            deals: [
                DealWithSchedules(
                    deal: Deal(venueId: venueId, title: "Happy Hour"),
                    schedules: []
                ),
            ]
        )

        let dealId = try #require(try dealRepository.find(venueId: venueId).first?.deal.id)
        try dealRepository.updateStatus(id: dealId, status: .approved)

        let found = try dealRepository.find(venueId: venueId)
        #expect(found.count == 1)
        #expect(found[0].deal.status == .approved)
    }
}
