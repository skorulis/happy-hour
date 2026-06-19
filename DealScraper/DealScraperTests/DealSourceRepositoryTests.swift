//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct DealSourceRepositoryTests {

    @Test func upsertInsertsNewSources() throws {
        let store = SQLStore.inMemory()
        let venueRepository = VenueRepository(store: store)
        let dealSourceRepository = DealSourceRepository(store: store)

        try venueRepository.upsert(Venue(
            googleMapId: "places/test",
            name: "Test Pub",
            lat: 0,
            lng: 0,
            websiteUri: "https://example.com",
            json: "{}"
        ))

        let venue = try #require(try venueRepository.find(googleMapId: "places/test"))
        let venueId = try #require(venue.id)

        let source = DealSource(
            venueId: venueId,
            url: "https://example.com/menu.pdf",
            type: .pdf
        )

        let newCount = try dealSourceRepository.upsert(sources: [source], forVenueId: venueId)
        #expect(newCount == 1)

        let found = try dealSourceRepository.find(venueId: venueId)
        #expect(found.count == 1)
        #expect(found[0].status == .new)
    }

    @Test func upsertDedupesByURLAndPreservesApprovedStatus() throws {
        let store = SQLStore.inMemory()
        let venueRepository = VenueRepository(store: store)
        let dealSourceRepository = DealSourceRepository(store: store)

        try venueRepository.upsert(Venue(
            googleMapId: "places/test",
            name: "Test Pub",
            lat: 0,
            lng: 0,
            websiteUri: "https://example.com",
            json: "{}"
        ))

        let venue = try #require(try venueRepository.find(googleMapId: "places/test"))
        let venueId = try #require(venue.id)

        let originalDate = Date(timeIntervalSince1970: 1_000)
        let approved = DealSource(
            venueId: venueId,
            url: "https://example.com/specials",
            type: .webpage,
            status: .approved,
            date: originalDate
        )
        _ = try dealSourceRepository.upsert(sources: [approved], forVenueId: venueId)

        let refreshedDate = Date(timeIntervalSince1970: 2_000)
        let rediscovered = DealSource(
            venueId: venueId,
            url: "https://example.com/specials",
            type: .webpage,
            status: .new,
            date: refreshedDate
        )

        let newCount = try dealSourceRepository.upsert(sources: [rediscovered], forVenueId: venueId)
        #expect(newCount == 0)

        let found = try #require(try dealSourceRepository.find(venueId: venueId).first)
        #expect(found.status == .approved)
        #expect(found.date == refreshedDate)
    }

    @Test func upsertPersistsSourceURL() throws {
        let store = SQLStore.inMemory()
        let venueRepository = VenueRepository(store: store)
        let dealSourceRepository = DealSourceRepository(store: store)

        try venueRepository.upsert(Venue(
            googleMapId: "places/test",
            name: "Test Pub",
            lat: 0,
            lng: 0,
            websiteUri: "https://example.com",
            json: "{}"
        ))

        let venue = try #require(try venueRepository.find(googleMapId: "places/test"))
        let venueId = try #require(venue.id)

        let source = DealSource(
            venueId: venueId,
            url: "https://example.com/menu.png",
            sourceURL: "https://example.com/specials",
            type: .image
        )

        _ = try dealSourceRepository.upsert(sources: [source], forVenueId: venueId)

        let found = try #require(try dealSourceRepository.find(venueId: venueId).first)
        #expect(found.sourceURL == "https://example.com/specials")
    }

    @Test func upsertPersistsTextPieces() throws {
        let store = SQLStore.inMemory()
        let venueRepository = VenueRepository(store: store)
        let dealSourceRepository = DealSourceRepository(store: store)

        try venueRepository.upsert(Venue(
            googleMapId: "places/test",
            name: "Test Pub",
            lat: 0,
            lng: 0,
            websiteUri: "https://example.com",
            json: "{}"
        ))

        let venue = try #require(try venueRepository.find(googleMapId: "places/test"))
        let venueId = try #require(venue.id)

        let blocks = [
            ContentBlock(title: "Happy Hour", text: "$5 pints", links: []),
        ]
        let source = DealSource(
            venueId: venueId,
            url: "https://example.com/specials",
            type: .webpage,
            textPieces: .contentBlocks(blocks)
        )

        _ = try dealSourceRepository.upsert(sources: [source], forVenueId: venueId)

        let found = try #require(try dealSourceRepository.find(venueId: venueId).first)
        #expect(found.textPieces == .contentBlocks(blocks))
    }

    @Test func updateStatusChangesSourceStatus() throws {
        let store = SQLStore.inMemory()
        let venueRepository = VenueRepository(store: store)
        let dealSourceRepository = DealSourceRepository(store: store)

        try venueRepository.upsert(Venue(
            googleMapId: "places/test",
            name: "Test Pub",
            lat: 0,
            lng: 0,
            websiteUri: "https://example.com",
            json: "{}"
        ))

        let venue = try #require(try venueRepository.find(googleMapId: "places/test"))
        let venueId = try #require(venue.id)

        _ = try dealSourceRepository.upsert(sources: [
            DealSource(venueId: venueId, url: "https://example.com/specials", type: .webpage),
        ], forVenueId: venueId)

        let source = try #require(try dealSourceRepository.find(venueId: venueId).first)
        let sourceId = try #require(source.id)

        try dealSourceRepository.updateStatus(id: sourceId, status: .approved)
        #expect(try dealSourceRepository.find(venueId: venueId).first?.status == .approved)

        try dealSourceRepository.updateStatus(id: sourceId, status: .rejected)
        #expect(try dealSourceRepository.find(venueId: venueId).first?.status == .rejected)
    }

    @Test func deleteAllRemovesSourcesForVenue() throws {
        let store = SQLStore.inMemory()
        let venueRepository = VenueRepository(store: store)
        let dealSourceRepository = DealSourceRepository(store: store)

        try venueRepository.upsert(Venue(
            googleMapId: "places/test",
            name: "Test Pub",
            lat: 0,
            lng: 0,
            websiteUri: "https://example.com",
            json: "{}"
        ))

        let venue = try #require(try venueRepository.find(googleMapId: "places/test"))
        let venueId = try #require(venue.id)

        _ = try dealSourceRepository.upsert(sources: [
            DealSource(venueId: venueId, url: "https://example.com/menu.pdf", type: .pdf),
            DealSource(venueId: venueId, url: "https://example.com/specials", type: .webpage),
        ], forVenueId: venueId)

        let deleted = try dealSourceRepository.deleteAll(venueId: venueId)
        #expect(deleted == 2)
        #expect(try dealSourceRepository.find(venueId: venueId).isEmpty)
    }

    @Test func findApprovedExcludesNewAndRejectedSources() throws {
        let store = SQLStore.inMemory()
        let venueRepository = VenueRepository(store: store)
        let dealSourceRepository = DealSourceRepository(store: store)

        try venueRepository.upsert(Venue(
            googleMapId: "places/test",
            name: "Test Pub",
            lat: 0,
            lng: 0,
            websiteUri: "https://example.com",
            json: "{}"
        ))

        let venueId = try #require(try venueRepository.find(googleMapId: "places/test")?.id)

        _ = try dealSourceRepository.upsert(sources: [
            DealSource(
                venueId: venueId,
                url: "https://example.com/approved-image.png",
                type: .image,
                status: .approved
            ),
            DealSource(
                venueId: venueId,
                url: "https://example.com/new-page",
                type: .webpage,
                status: .new
            ),
            DealSource(
                venueId: venueId,
                url: "https://example.com/rejected-page",
                type: .webpage,
                status: .rejected
            ),
            DealSource(
                venueId: venueId,
                url: "https://example.com/menu.pdf",
                type: .pdf,
                status: .approved
            ),
        ], forVenueId: venueId)

        let approved = try dealSourceRepository.findApproved(venueId: venueId)
        #expect(approved.count == 2)
        #expect(Set(approved.map(\.url)).contains("https://example.com/approved-image.png"))
        #expect(Set(approved.map(\.url)).contains("https://example.com/menu.pdf"))
    }
}
