//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct VenueLinksRepositoryTests {

    private func makeVenueId(store: SQLStore) throws -> Int64 {
        let venueRepository = VenueRepository(store: store)
        try venueRepository.upsert(Venue(
            googleMapId: "places/ChIJTestLinks",
            name: "Link Test Pub",
            lat: -33.8688,
            lng: 151.2093,
            json: #"{"id":"places/ChIJTestLinks"}"#
        ))
        let venue = try #require(try venueRepository.find(googleMapId: "places/ChIJTestLinks"))
        return try #require(venue.id)
    }

    @Test func setMissingInsertsNewRow() throws {
        let store = SQLStore.inMemory()
        let repository = VenueLinksRepository(store: store)
        let venueId = try makeVenueId(store: store)

        try repository.setMissing(
            venueId: venueId,
            whatsOn: "https://pub.example.com/whats-on",
            instagram: "https://instagram.com/pub",
            facebook: nil
        )

        let found = try #require(try repository.find(venueId: venueId))
        #expect(found.whatsOn == "https://pub.example.com/whats-on")
        #expect(found.instagram == "https://instagram.com/pub")
        #expect(found.facebook == nil)

        let venue = try #require(try VenueRepository(store: store).find(id: venueId))
        #expect(venue.lastUpdate != nil)
    }

    @Test func setMissingFillsOnlyEmptyFieldsOnExistingRow() throws {
        let store = SQLStore.inMemory()
        let repository = VenueLinksRepository(store: store)
        let venueId = try makeVenueId(store: store)

        try repository.setMissing(
            venueId: venueId,
            whatsOn: "https://pub.example.com/whats-on",
            instagram: nil,
            facebook: nil
        )

        try repository.setMissing(
            venueId: venueId,
            whatsOn: "https://pub.example.com/events",
            instagram: "https://instagram.com/pub",
            facebook: "https://facebook.com/pub"
        )

        let found = try #require(try repository.find(venueId: venueId))
        #expect(found.whatsOn == "https://pub.example.com/whats-on")
        #expect(found.instagram == "https://instagram.com/pub")
        #expect(found.facebook == "https://facebook.com/pub")
    }

    @Test func setMissingDoesNotOverwriteExistingInstagram() throws {
        let store = SQLStore.inMemory()
        let repository = VenueLinksRepository(store: store)
        let venueId = try makeVenueId(store: store)

        try repository.setMissing(
            venueId: venueId,
            whatsOn: nil,
            instagram: "https://instagram.com/existing",
            facebook: nil
        )

        try repository.setMissing(
            venueId: venueId,
            whatsOn: nil,
            instagram: "https://instagram.com/new",
            facebook: nil
        )

        let found = try #require(try repository.find(venueId: venueId))
        #expect(found.instagram == "https://instagram.com/existing")
    }
}
