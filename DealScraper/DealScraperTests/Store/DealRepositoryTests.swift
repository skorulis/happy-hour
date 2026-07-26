//Created by Alex Skorulis on 17/6/2026.

import Foundation
import GRDB
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

    @Test func replaceAllAndUpdateRoundTripProducts() throws {
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
                    schedules: [],
                    products: [
                        DealProduct(dealId: 0, product: "beer", price: 8),
                        DealProduct(dealId: 0, product: "wine", price: nil),
                    ]
                ),
            ]
        )

        let found = try dealRepository.find(venueId: venueId)
        #expect(found.count == 1)
        #expect(found[0].products.count == 2)
        #expect(found[0].products.map(\.product) == ["beer", "wine"])
        #expect(found[0].products.map(\.price) == [8, nil])

        let dealId = try #require(found[0].deal.id)
        try dealRepository.update(
            id: dealId,
            title: "Happy Hour",
            details: nil,
            conditions: nil,
            sourceURL: nil,
            creativeURL: nil,
            products: [
                DealProduct(dealId: dealId, product: "cocktails", price: 14),
            ],
            status: .approved
        )

        let updated = try dealRepository.find(venueId: venueId)
        #expect(updated.count == 1)
        #expect(updated[0].products.count == 1)
        #expect(updated[0].products[0].product == "cocktails")
        #expect(updated[0].products[0].price == 14)
    }

    @Test func replaceAllBumpsVenueLastUpdate() throws {
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
        let before = try #require(try venueRepository.find(id: venueId)?.lastUpdate)

        Thread.sleep(forTimeInterval: 0.01)

        let deal = Deal(
            venueId: venueId,
            title: "Happy Hour",
            details: "$8 wines"
        )
        _ = try dealRepository.replaceAll(
            venueId: venueId,
            deals: [DealWithSchedules(deal: deal, schedules: [])]
        )

        let after = try #require(try venueRepository.find(id: venueId)?.lastUpdate)
        #expect(after > before)
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

        try venueRepository.updateLastExtractionDate(venueId: venueId, date: .now)

        let deleted = try dealRepository.deleteAll(venueId: venueId)
        #expect(deleted == 1)
        #expect(try dealRepository.find(venueId: venueId).isEmpty)

        let venue = try #require(try venueRepository.find(id: venueId))
        #expect(venue.lastExtractionDate == nil)
    }

    @Test func findNewReturnsOnlyNewDealsAcrossVenues() throws {
        let store = SQLStore.inMemory()
        let venueRepository = VenueRepository(store: store)
        let dealRepository = DealRepository(store: store)

        try venueRepository.upsert(Venue(
            googleMapId: "places/a",
            name: "Venue A",
            lat: 0,
            lng: 0,
            json: "{}"
        ))
        try venueRepository.upsert(Venue(
            googleMapId: "places/b",
            name: "Venue B",
            lat: 0,
            lng: 0,
            json: "{}"
        ))

        let venueAId = try #require(try venueRepository.find(googleMapId: "places/a")?.id)
        let venueBId = try #require(try venueRepository.find(googleMapId: "places/b")?.id)

        _ = try dealRepository.replaceAll(
            venueId: venueAId,
            deals: [
                DealWithSchedules(
                    deal: Deal(venueId: venueAId, title: "New Deal A", status: .new),
                    schedules: []
                ),
                DealWithSchedules(
                    deal: Deal(venueId: venueAId, title: "Approved Deal", status: .approved),
                    schedules: []
                ),
            ]
        )
        _ = try dealRepository.replaceAll(
            venueId: venueBId,
            deals: [
                DealWithSchedules(
                    deal: Deal(venueId: venueBId, title: "New Deal B", status: .new),
                    schedules: []
                ),
                DealWithSchedules(
                    deal: Deal(venueId: venueBId, title: "Rejected Deal", status: .rejected),
                    schedules: []
                ),
            ]
        )

        let pending = try dealRepository.findNew()
        #expect(pending.count == 2)
        #expect(Set(pending.compactMap(\.deal.title)) == ["New Deal A", "New Deal B"])
    }

    @Test func updatePersistsDealTextAndStatus() throws {
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
                    deal: Deal(
                        venueId: venueId,
                        title: "Happy Hour",
                        details: "$8 wines",
                        conditions: "Dine-in only"
                    ),
                    schedules: []
                ),
            ]
        )

        let dealId = try #require(try dealRepository.find(venueId: venueId).first?.deal.id)
        try dealRepository.update(
            id: dealId,
            title: "Edited Title",
            details: "Edited details",
            conditions: "Edited conditions",
            sourceURL: "https://example.com/page",
            creativeURL: "https://example.com/image.png",
            status: .approved
        )

        let found = try dealRepository.find(venueId: venueId)
        #expect(found.count == 1)
        #expect(found[0].deal.title == "Edited Title")
        #expect(found[0].deal.details == "Edited details")
        #expect(found[0].deal.conditions == "Edited conditions")
        #expect(found[0].deal.sourceURL == "https://example.com/page")
        #expect(found[0].deal.creativeURL == "https://example.com/image.png")
        #expect(found[0].deal.status == .approved)
        #expect(found[0].deal.updateDate != nil)
    }

    @Test func updateStatusDoesNotSetUpdateDate() throws {
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
        #expect(found[0].deal.updateDate == nil)
    }

    @Test func duplicateSetsUpdateDate() throws {
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
        let duplicated = try #require(try dealRepository.duplicate(id: dealId))

        #expect(duplicated.deal.updateDate != nil)
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

    @Test func replaceAllPersistsAndLoadsSourceLinks() throws {
        let store = SQLStore.inMemory()
        let venueRepository = VenueRepository(store: store)
        let dealRepository = DealRepository(store: store)
        let dealSourceRepository = DealSourceRepository(store: store)

        try venueRepository.upsert(Venue(
            googleMapId: "places/test",
            name: "Test Pub",
            lat: 0,
            lng: 0,
            json: "{}"
        ))

        let venueId = try #require(try venueRepository.find(googleMapId: "places/test")?.id)

        _ = try dealSourceRepository.upsert(
            sources: [
                DealSource(venueId: venueId, url: "https://example.com/a", type: .webpage),
                DealSource(venueId: venueId, url: "https://example.com/b", type: .image),
            ],
            forVenueId: venueId
        )
        let sources = try dealSourceRepository.find(venueId: venueId)
        #expect(sources.count == 2)
        let sourceIds = sources.compactMap(\.id)
        #expect(sourceIds.count == 2)

        _ = try dealRepository.replaceAll(
            venueId: venueId,
            deals: [
                DealWithSchedules(
                    deal: Deal(venueId: venueId, title: "Happy Hour"),
                    schedules: [],
                    sourceIds: sourceIds
                ),
            ]
        )

        let found = try dealRepository.find(venueId: venueId)
        #expect(found.count == 1)
        #expect(Set(found[0].sourceIds) == Set(sourceIds))
    }

    @Test func replaceAllSkipsNonPositiveSourceIds() throws {
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
                    schedules: [],
                    sourceIds: [0, -1]
                ),
            ]
        )

        let found = try dealRepository.find(venueId: venueId)
        #expect(found.count == 1)
        #expect(found[0].sourceIds.isEmpty)
    }

    @Test func deleteCascadesSourceLinks() throws {
        let store = SQLStore.inMemory()
        let venueRepository = VenueRepository(store: store)
        let dealRepository = DealRepository(store: store)
        let dealSourceRepository = DealSourceRepository(store: store)

        try venueRepository.upsert(Venue(
            googleMapId: "places/test",
            name: "Test Pub",
            lat: 0,
            lng: 0,
            json: "{}"
        ))

        let venueId = try #require(try venueRepository.find(googleMapId: "places/test")?.id)

        _ = try dealSourceRepository.upsert(
            sources: [
                DealSource(venueId: venueId, url: "https://example.com/specials", type: .webpage),
            ],
            forVenueId: venueId
        )
        let sourceId = try #require(try dealSourceRepository.find(venueId: venueId).first?.id)

        _ = try dealRepository.replaceAll(
            venueId: venueId,
            deals: [
                DealWithSchedules(
                    deal: Deal(venueId: venueId, title: "Happy Hour"),
                    schedules: [],
                    sourceIds: [sourceId]
                ),
            ]
        )

        let dealId = try #require(try dealRepository.find(venueId: venueId).first?.deal.id)
        _ = try dealRepository.delete(id: dealId)

        let remainingLinks = try store.dbQueue.read { db in
            try DealSourceLink.filter(Column("deal_source_id") == sourceId).fetchCount(db)
        }
        #expect(remainingLinks == 0)
    }

    @Test func duplicateCopiesSourceLinks() throws {
        let store = SQLStore.inMemory()
        let venueRepository = VenueRepository(store: store)
        let dealRepository = DealRepository(store: store)
        let dealSourceRepository = DealSourceRepository(store: store)

        try venueRepository.upsert(Venue(
            googleMapId: "places/test",
            name: "Test Pub",
            lat: 0,
            lng: 0,
            json: "{}"
        ))

        let venueId = try #require(try venueRepository.find(googleMapId: "places/test")?.id)

        _ = try dealSourceRepository.upsert(
            sources: [
                DealSource(venueId: venueId, url: "https://example.com/specials", type: .webpage),
            ],
            forVenueId: venueId
        )
        let sourceId = try #require(try dealSourceRepository.find(venueId: venueId).first?.id)

        _ = try dealRepository.replaceAll(
            venueId: venueId,
            deals: [
                DealWithSchedules(
                    deal: Deal(venueId: venueId, title: "Happy Hour"),
                    schedules: [],
                    sourceIds: [sourceId]
                ),
            ]
        )

        let dealId = try #require(try dealRepository.find(venueId: venueId).first?.deal.id)
        let duplicated = try #require(try dealRepository.duplicate(id: dealId))

        #expect(duplicated.sourceIds == [sourceId])

        let all = try dealRepository.find(venueId: venueId)
        #expect(all.count == 2)
        #expect(all.allSatisfy { $0.sourceIds == [sourceId] })
    }
}
