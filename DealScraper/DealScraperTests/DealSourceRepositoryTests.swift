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
            type: .pdf,
            hash: "abc123"
        )

        let newCount = try dealSourceRepository.upsert(sources: [source], forVenueId: venueId)
        #expect(newCount == 1)

        let found = try dealSourceRepository.find(venueId: venueId)
        #expect(found.count == 1)
        #expect(found[0].status == .new)
    }

    @Test func upsertDedupesByHashAndPreservesApprovedStatus() throws {
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
            hash: "hash-specials",
            status: .approved,
            date: originalDate
        )
        _ = try dealSourceRepository.upsert(sources: [approved], forVenueId: venueId)

        let refreshedDate = Date(timeIntervalSince1970: 2_000)
        let rediscovered = DealSource(
            venueId: venueId,
            url: "https://example.com/specials",
            type: .webpage,
            hash: "hash-specials",
            status: .new,
            date: refreshedDate
        )

        let newCount = try dealSourceRepository.upsert(sources: [rediscovered], forVenueId: venueId)
        #expect(newCount == 0)

        let found = try #require(try dealSourceRepository.find(venueId: venueId).first)
        #expect(found.status == .approved)
        #expect(found.date == refreshedDate)
    }
}
