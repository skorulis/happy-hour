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

    @Test func upsertPlacesPersistsRegularOpeningHoursInJson() throws {
        let repository = VenueRepository(store: SQLStore.inMemory())

        let place = GooglePlace(
            id: "places/ChIJHours",
            displayName: .init(text: "Hours Pub", languageCode: "en"),
            location: .init(latitude: -33.8600, longitude: 151.2100),
            formattedAddress: "1 Circular Quay, Sydney",
            websiteUri: "https://hourspub.example.com",
            types: ["bar"],
            regularOpeningHours: GooglePlace.OpeningHours(
                periods: [
                    GooglePlace.OpeningHours.Period(
                        open: GooglePlace.OpeningHours.Period.Point(
                            day: 1, hour: 11, minute: 0, truncated: nil
                        ),
                        close: GooglePlace.OpeningHours.Period.Point(
                            day: 1, hour: 22, minute: 0, truncated: nil
                        )
                    ),
                ],
                weekdayDescriptions: ["Monday: 11:00 AM – 10:00 PM"],
                openNow: true
            )
        )

        try repository.upsert(places: [place])

        let found = try #require(try repository.find(googleMapId: "places/ChIJHours"))
        #expect(found.json.contains("regularOpeningHours"))
        #expect(found.json.contains("weekdayDescriptions"))
        #expect(found.json.contains("openNow"))
    }

    @Test func upsertPlacesMapsGooglePlaceToVenue() throws {
        let store = SQLStore.inMemory()
        let repository = VenueRepository(store: store)

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

        let suburb = try #require(try SuburbRepository(store: store).find(
            name: "Sydney",
            postcode: nil
        ))
        #expect(found.suburbId == suburb.id)
    }

    @Test func upsertPlacesMarksVenueBrokenWhenWebsiteMissing() throws {
        let repository = VenueRepository(store: SQLStore.inMemory())

        let place = GooglePlace(
            id: "places/ChIJNoWebsite",
            displayName: .init(text: "No Website Pub", languageCode: "en"),
            location: .init(latitude: -33.8600, longitude: 151.2100),
            formattedAddress: "1 Circular Quay, Sydney",
            websiteUri: nil,
            types: ["bar"]
        )

        try repository.upsert(places: [place])

        let found = try #require(try repository.find(googleMapId: "places/ChIJNoWebsite"))
        #expect(found.websiteUri == nil)
        #expect(found.status == .broken)
    }

    @Test func upsertPlacesReturnsNewCount() throws {
        let repository = VenueRepository(store: SQLStore.inMemory())

        let place = GooglePlace(
            id: "places/ChIJFromAPI",
            displayName: .init(text: "Harbour Pub", languageCode: "en"),
            location: .init(latitude: -33.8600, longitude: 151.2100),
            formattedAddress: "1 Circular Quay, Sydney",
            websiteUri: "https://harbourpub.example.com",
            types: ["bar"]
        )

        let firstNewCount = try repository.upsert(places: [place])
        #expect(firstNewCount == 1)

        let secondNewCount = try repository.upsert(places: [place])
        #expect(secondNewCount == 0)
    }

    @Test func updateStatusPersistsVenueStatus() throws {
        let repository = VenueRepository(store: SQLStore.inMemory())

        try repository.upsert(Venue(
            googleMapId: "places/ChIJTest123",
            name: "The Royal Pub",
            lat: -33.8688,
            lng: 151.2093,
            json: "{}"
        ))

        let venueId = try #require(try repository.find(googleMapId: "places/ChIJTest123")?.id)
        try repository.updateStatus(venueId: venueId, status: .broken)

        let found = try #require(try repository.find(id: venueId))
        #expect(found.status == .broken)
    }

    @Test func upsertPreservesExistingStatus() throws {
        let repository = VenueRepository(store: SQLStore.inMemory())

        try repository.upsert(Venue(
            googleMapId: "places/ChIJTest123",
            name: "The Royal Pub",
            lat: -33.8688,
            lng: 151.2093,
            status: .broken,
            json: #"{"name":"Old Name"}"#
        ))

        try repository.upsert(Venue(
            googleMapId: "places/ChIJTest123",
            name: "New Name",
            lat: -33.8700,
            lng: 151.2100,
            json: #"{"name":"New Name"}"#
        ))

        let found = try #require(try repository.find(googleMapId: "places/ChIJTest123"))
        #expect(found.name == "New Name")
        #expect(found.status == .broken)
    }

    @Test func upsertPreservesExistingHeroImageAndDates() throws {
        let repository = VenueRepository(store: SQLStore.inMemory())
        let crawlDate = Date(timeIntervalSince1970: 1_700_000_000)
        let extractionDate = Date(timeIntervalSince1970: 1_700_100_000)
        let heroURL = "https://example.com/hero.jpg"

        let place = GooglePlace(
            id: "places/ChIJFromAPI",
            displayName: .init(text: "Harbour Pub", languageCode: "en"),
            location: .init(latitude: -33.8600, longitude: 151.2100),
            formattedAddress: "1 Circular Quay, Sydney",
            websiteUri: "https://harbourpub.example.com",
            types: ["bar"]
        )

        try repository.upsert(places: [place])

        let venueId = try #require(try repository.find(googleMapId: "places/ChIJFromAPI")?.id)
        try repository.updateHeroImage(venueId: venueId, url: heroURL)
        try repository.updateLastCrawlDate(venueId: venueId, date: crawlDate)
        try repository.updateLastExtractionDate(venueId: venueId, date: extractionDate)

        try repository.upsert(places: [place])

        let found = try #require(try repository.find(id: venueId))
        #expect(found.heroImage == heroURL)
        #expect(found.lastCrawlDate == crawlDate)
        #expect(found.lastExtractionDate == extractionDate)
    }

    @Test func updateHeroImagePersistsURL() throws {
        let repository = VenueRepository(store: SQLStore.inMemory())

        try repository.upsert(Venue(
            googleMapId: "places/ChIJTest123",
            name: "The Royal Pub",
            lat: -33.8688,
            lng: 151.2093,
            json: "{}"
        ))

        let venueId = try #require(try repository.find(googleMapId: "places/ChIJTest123")?.id)
        let heroURL = "https://example.com/hero.jpg"
        try repository.updateHeroImage(venueId: venueId, url: heroURL)

        let found = try #require(try repository.find(id: venueId))
        #expect(found.heroImage == heroURL)
    }

    @Test func deleteRemovesVenueAndRelatedRecords() throws {
        let store = SQLStore.inMemory()
        let venueRepository = VenueRepository(store: store)
        let dealSourceRepository = DealSourceRepository(store: store)
        let dealRepository = DealRepository(store: store)
        let venueLinksRepository = VenueLinksRepository(store: store)

        try venueRepository.upsert(Venue(
            googleMapId: "places/ChIJDelete",
            name: "Delete Me Pub",
            lat: -33.8688,
            lng: 151.2093,
            json: "{}"
        ))

        let venueId = try #require(try venueRepository.find(googleMapId: "places/ChIJDelete")?.id)

        try venueLinksRepository.setMissing(
            venueId: venueId,
            whatsOn: "https://example.com/whats-on",
            instagram: nil,
            facebook: nil
        )

        try dealSourceRepository.upsert(
            sources: [
                DealSource(
                    venueId: venueId,
                    url: "https://example.com/deals",
                    type: .webpage,
                    status: .approved
                ),
            ],
            forVenueId: venueId
        )

        try dealRepository.replaceAll(
            venueId: venueId,
            deals: [
                DealWithSchedules(
                    deal: Deal(venueId: venueId, title: "Happy Hour"),
                    schedules: []
                ),
            ]
        )

        #expect(try venueRepository.delete(id: venueId))
        #expect(try venueRepository.find(id: venueId) == nil)
        #expect(try dealSourceRepository.find(venueId: venueId).isEmpty)
        #expect(try dealRepository.find(venueId: venueId).isEmpty)
        #expect(try venueLinksRepository.find(venueId: venueId) == nil)
        #expect(try venueRepository.delete(id: venueId) == false)
    }
}
