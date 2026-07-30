//Created by Alex Skorulis on 30/7/2026.

import Foundation
import Testing
@testable import DealScraper

struct VenueFeatureRepositoryTests {

    private func makeVenueId(store: SQLStore) throws -> Int64 {
        let venueRepository = VenueRepository(store: store)
        try venueRepository.upsert(Venue(
            googleMapId: "places/ChIJTestFeatures",
            name: "Feature Test Pub",
            lat: -33.8688,
            lng: 151.2093,
            json: #"{"id":"places/ChIJTestFeatures"}"#
        ))
        let venue = try #require(try venueRepository.find(googleMapId: "places/ChIJTestFeatures"))
        return try #require(venue.id)
    }

    @Test func replaceAllAndFindRoundTrip() throws {
        let store = SQLStore.inMemory()
        let repository = VenueFeatureRepository(store: store)
        let venueId = try makeVenueId(store: store)

        try repository.replaceAll(
            venueId: venueId,
            features: ["rooftop", "beer garden", "courtyard"]
        )

        let found = try repository.find(venueId: venueId)
        #expect(found.map(\.feature) == ["beer garden", "courtyard", "rooftop"])

        let venue = try #require(try VenueRepository(store: store).find(id: venueId))
        #expect(venue.lastUpdate != nil)
    }

    @Test func replaceAllReplacesExistingRows() throws {
        let store = SQLStore.inMemory()
        let repository = VenueFeatureRepository(store: store)
        let venueId = try makeVenueId(store: store)

        try repository.replaceAll(venueId: venueId, features: ["courtyard", "rooftop"])
        try repository.replaceAll(venueId: venueId, features: ["beer garden"])

        let found = try repository.find(venueId: venueId)
        #expect(found.map(\.feature) == ["beer garden"])
    }

    @Test func replaceAllRejectsUnknownFeature() throws {
        let store = SQLStore.inMemory()
        let repository = VenueFeatureRepository(store: store)
        let venueId = try makeVenueId(store: store)

        do {
            try repository.replaceAll(venueId: venueId, features: ["sports bar"])
            Issue.record("Expected unknownFeature error")
        } catch VenueFeatureRepositoryError.unknownFeature(let name) {
            #expect(name == "sports bar")
        }
    }
}
