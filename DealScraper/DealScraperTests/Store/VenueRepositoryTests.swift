//Created by Alex Skorulis on 15/6/2026.

import Foundation
import GRDB
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

    @Test func upsertPlacesPrefersAddressSuburbOverCrawlSuburb() throws {
        let store = SQLStore.inMemory()
        let repository = VenueRepository(store: store)
        let crawlSuburbId = try store.dbQueue.write { db -> Int64 in
            var mortlake = Suburb(name: "Mortlake", postcode: "2137", state: "NSW")
            try mortlake.insert(db)
            var gladesville = Suburb(name: "Gladesville", postcode: "2111", state: "NSW")
            try gladesville.insert(db)
            return try #require(mortlake.id)
        }

        let place = GooglePlace(
            id: "places/ChIJGladesville",
            displayName: .init(text: "Victoria Rd Pub", languageCode: "en"),
            location: .init(latitude: -33.8270, longitude: 151.1270),
            formattedAddress: "386 Victoria Rd, Gladesville NSW 2111",
            websiteUri: "https://victoriardpub.example.com",
            types: ["bar"]
        )

        try repository.upsert(places: [place], suburbId: crawlSuburbId)

        let found = try #require(try repository.find(googleMapId: "places/ChIJGladesville"))
        let gladesvilleId = try store.dbQueue.read { db in
            try Suburb
                .filter(Column("name") == "Gladesville")
                .filter(Column("postcode") == "2111")
                .fetchOne(db)?
                .id
        }
        #expect(found.suburbId == gladesvilleId)
        #expect(found.suburbId != crawlSuburbId)
    }

    @Test func upsertPlacesFallsBackToCrawlSuburbWhenAddressUnparseable() throws {
        let store = SQLStore.inMemory()
        let repository = VenueRepository(store: store)
        let crawlSuburbId = try store.dbQueue.write { db -> Int64 in
            var suburb = Suburb(name: "Newtown", postcode: "2042", state: "NSW")
            try suburb.insert(db)
            return try #require(suburb.id)
        }

        let place = GooglePlace(
            id: "places/ChIJNoAddress",
            displayName: .init(text: "Mystery Pub", languageCode: "en"),
            location: .init(latitude: -33.8700, longitude: 151.2100),
            formattedAddress: nil,
            websiteUri: "https://mysterypub.example.com",
            types: ["bar"]
        )

        try repository.upsert(places: [place], suburbId: crawlSuburbId)

        let found = try #require(try repository.find(googleMapId: "places/ChIJNoAddress"))
        #expect(found.suburbId == crawlSuburbId)
    }

    @Test func upsertPlacesMapsGooglePlaceToVenue() throws {
        let store = SQLStore.inMemory()
        let repository = VenueRepository(store: store)
        let suburbId = try store.dbQueue.write { db -> Int64 in
            var suburb = Suburb(name: "Sydney", postcode: "2000", state: "NSW")
            try suburb.insert(db)
            return try #require(suburb.id)
        }

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
        #expect(found.suburbId == suburbId)
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
        try repository.updateLastCrawlDate(venueId: venueId, date: crawlDate, url: "https://old.example.com")
        try repository.updateLastExtractionDate(venueId: venueId, date: extractionDate)

        try repository.upsert(places: [place])

        let found = try #require(try repository.find(id: venueId))
        #expect(found.heroImage == heroURL)
        #expect(found.lastCrawlDate == crawlDate)
        #expect(found.lastCrawlUrl == "https://old.example.com")
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

    @Test func upsertPlacesSkipsClosedVenues() throws {
        let repository = VenueRepository(store: SQLStore.inMemory())

        let operational = GooglePlace(
            id: "places/ChIJOpen",
            displayName: .init(text: "Open Pub", languageCode: "en"),
            location: .init(latitude: -33.8600, longitude: 151.2100),
            formattedAddress: "1 Circular Quay, Sydney",
            websiteUri: "https://openpub.example.com",
            types: ["bar"],
            businessStatus: .operational
        )
        let temporarilyClosed = GooglePlace(
            id: "places/ChIJTempClosed",
            displayName: .init(text: "Temp Closed Pub", languageCode: "en"),
            location: .init(latitude: -33.8610, longitude: 151.2110),
            formattedAddress: "2 Circular Quay, Sydney",
            websiteUri: "https://tempclosed.example.com",
            types: ["bar"],
            businessStatus: .closedTemporarily
        )
        let permanentlyClosed = GooglePlace(
            id: "places/ChIJPermClosed",
            displayName: .init(text: "Closed Pub", languageCode: "en"),
            location: .init(latitude: -33.8620, longitude: 151.2120),
            formattedAddress: "3 Circular Quay, Sydney",
            websiteUri: "https://closedpub.example.com",
            types: ["bar"],
            businessStatus: .closedPermanently
        )

        let newCount = try repository.upsert(places: [operational, temporarilyClosed, permanentlyClosed])
        #expect(newCount == 1)

        let all = try repository.all()
        #expect(all.count == 1)
        #expect(all.first?.googleMapId == "places/ChIJOpen")
    }

    @Test func upsertPlacesRemovesExistingPermanentlyClosedVenue() throws {
        let repository = VenueRepository(store: SQLStore.inMemory())

        let place = GooglePlace(
            id: "places/ChIJWasOpen",
            displayName: .init(text: "Former Pub", languageCode: "en"),
            location: .init(latitude: -33.8600, longitude: 151.2100),
            formattedAddress: "1 Circular Quay, Sydney",
            websiteUri: "https://formerpub.example.com",
            types: ["bar"],
            businessStatus: .operational
        )
        try repository.upsert(places: [place])
        #expect(try repository.find(googleMapId: "places/ChIJWasOpen") != nil)

        let closedPlace = GooglePlace(
            id: place.id,
            displayName: place.displayName,
            location: place.location,
            formattedAddress: place.formattedAddress,
            websiteUri: place.websiteUri,
            types: place.types,
            businessStatus: .closedPermanently
        )
        let newCount = try repository.upsert(places: [closedPlace])
        #expect(newCount == 0)
        #expect(try repository.find(googleMapId: "places/ChIJWasOpen") == nil)
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
