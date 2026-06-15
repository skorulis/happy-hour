//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct VenueRepositoryTests {

    @Test func upsertInsertsAndFindsVenue() throws {
        let repository = VenueRepository(store: SQLStore.inMemory())

        let venue = Venue(
            googleMapId: "places/ChIJTest123",
            name: "The Royal Pub",
            lat: -33.8688,
            lng: 151.2093,
            json: #"{"id":"places/ChIJTest123"}"#
        )

        try repository.upsert(venue)

        let found = try #require(try repository.find(googleMapId: "places/ChIJTest123"))
        #expect(found.name == "The Royal Pub")
        #expect(found.lat == -33.8688)
        #expect(found.lng == 151.2093)
        #expect(found.id != nil)

        let all = try repository.all()
        #expect(all.count == 1)
    }

    @Test func upsertUpdatesExistingVenueByGoogleMapId() throws {
        let repository = VenueRepository(store: SQLStore.inMemory())

        try repository.upsert(Venue(
            googleMapId: "places/ChIJTest123",
            name: "Old Name",
            lat: -33.8688,
            lng: 151.2093,
            json: #"{"name":"Old Name"}"#
        ))

        try repository.upsert(Venue(
            googleMapId: "places/ChIJTest123",
            name: "New Name",
            lat: -33.8700,
            lng: 151.2100,
            json: #"{"name":"New Name"}"#
        ))

        let all = try repository.all()
        #expect(all.count == 1)

        let found = try #require(try repository.find(googleMapId: "places/ChIJTest123"))
        #expect(found.name == "New Name")
        #expect(found.lat == -33.8700)
        #expect(found.lng == 151.2100)
        #expect(found.json == #"{"name":"New Name"}"#)
    }

    @Test func upsertPlacesMapsGooglePlaceToVenue() throws {
        let repository = VenueRepository(store: SQLStore.inMemory())

        let place = GooglePlace(
            id: "places/ChIJFromAPI",
            displayName: .init(text: "Harbour Pub", languageCode: "en"),
            location: .init(latitude: -33.8600, longitude: 151.2100),
            formattedAddress: "1 Circular Quay, Sydney",
            websiteUri: "https://harbourpub.example.com",
            types: ["bar"]
        )

        try repository.upsert(places: [place])

        let found = try #require(try repository.find(googleMapId: "places/ChIJFromAPI"))
        #expect(found.name == "Harbour Pub")
        #expect(found.lat == -33.8600)
        #expect(found.lng == 151.2100)
        #expect(found.googleMapId == "places/ChIJFromAPI")
        #expect(found.websiteUri == "https://harbourpub.example.com")
        #expect(found.lastCrawlDate == nil)
        #expect(found.json.contains("Harbour Pub"))
    }
}
