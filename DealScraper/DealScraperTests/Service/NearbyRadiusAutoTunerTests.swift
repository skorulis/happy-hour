// Created by Alexander Skorulis on 28/7/2026.

import Foundation
import GRDB
import Testing
@testable import DealScraper

struct NearbyRadiusAutoTunerTests {

    @Test func snapToLadderRoundsUpToNextRung() {
        #expect(NearbyRadiusAutoTuner.snapToLadder(distanceKm: 0.1) == 2)
        #expect(NearbyRadiusAutoTuner.snapToLadder(distanceKm: 2) == 2)
        #expect(NearbyRadiusAutoTuner.snapToLadder(distanceKm: 2.1) == 5)
        #expect(NearbyRadiusAutoTuner.snapToLadder(distanceKm: 9.9) == 10)
        #expect(NearbyRadiusAutoTuner.snapToLadder(distanceKm: 25) == 25)
        #expect(NearbyRadiusAutoTuner.snapToLadder(distanceKm: 100) == 100)
    }

    @Test func snapToLadderReturnsNilBeyondMax() {
        #expect(NearbyRadiusAutoTuner.snapToLadder(distanceKm: 100.1) == nil)
        #expect(NearbyRadiusAutoTuner.snapToLadder(distanceKm: 200) == nil)
    }

    @Test func defaultRadiusKmMatchesAreaFormula() {
        #expect(NearbyRadiusAutoTuner.defaultRadiusKm(sqkm: nil) == NearbyRadiusAutoTuner.defaultBufferKm)
        #expect(NearbyRadiusAutoTuner.defaultRadiusKm(sqkm: 0) == NearbyRadiusAutoTuner.defaultBufferKm)
        #expect(
            abs(NearbyRadiusAutoTuner.defaultRadiusKm(sqkm: .pi) - (1 + NearbyRadiusAutoTuner.defaultBufferKm))
                < 0.0001
        )
    }

    @Test func tuneLeavesBlankWhenDefaultRadiusFindsApprovedDeal() throws {
        let store = SQLStore.inMemory()
        let suburbRepository = SuburbRepository(store: store)
        let venueRepository = VenueRepository(store: store)
        let tuner = NearbyRadiusAutoTuner(
            venueRepository: venueRepository,
            suburbRepository: suburbRepository
        )

        let originLat = -33.8688
        let originLng = 151.2093
        let nearbyLng = originLng + (1.0 / (111.0 * cos(originLat * .pi / 180.0)))

        let suburbId = try insertSuburb(
            Suburb(
                name: "Origin",
                postcode: "2000",
                state: "NSW",
                lat: originLat,
                lng: originLng,
                sqkm: .pi,
                nearbyRadiusKm: 10
            ),
            store: store
        )
        let otherSuburbId = try insertSuburb(
            Suburb(name: "Other", postcode: "2010", state: "NSW", lat: originLat, lng: nearbyLng),
            store: store
        )
        let venueId = try insertVenue(
            name: "Nearby Pub",
            googleMapId: "nearby-1",
            lat: originLat,
            lng: nearbyLng,
            suburbId: otherSuburbId,
            store: store
        )
        try insertApprovedDeal(venueId: venueId, store: store)

        let suburb = try #require(try suburbRepository.find(id: suburbId))
        #expect(try tuner.tune(suburb: suburb) == .cleared)

        let updated = try #require(try suburbRepository.find(id: suburbId))
        #expect(updated.nearbyRadiusKm == nil)
    }

    @Test func tuneSetsLadderRadiusWhenDefaultIsInsufficient() throws {
        let store = SQLStore.inMemory()
        let suburbRepository = SuburbRepository(store: store)
        let venueRepository = VenueRepository(store: store)
        let tuner = NearbyRadiusAutoTuner(
            venueRepository: venueRepository,
            suburbRepository: suburbRepository
        )

        let originLat = -33.8688
        let originLng = 151.2093
        let nearbyLng = originLng + (3.3 / (111.0 * cos(originLat * .pi / 180.0)))

        let suburbId = try insertSuburb(
            Suburb(name: "Origin", postcode: "2000", state: "NSW", lat: originLat, lng: originLng),
            store: store
        )
        let otherSuburbId = try insertSuburb(
            Suburb(name: "Other", postcode: "2010", state: "NSW", lat: originLat, lng: nearbyLng),
            store: store
        )
        let venueId = try insertVenue(
            name: "Nearby Pub",
            googleMapId: "nearby-1",
            lat: originLat,
            lng: nearbyLng,
            suburbId: otherSuburbId,
            store: store
        )
        try insertApprovedDeal(venueId: venueId, store: store)
        let localVenueId = try insertVenue(
            name: "Local Pub",
            googleMapId: "local-1",
            lat: originLat + 0.001,
            lng: originLng,
            suburbId: suburbId,
            store: store
        )
        try insertApprovedDeal(venueId: localVenueId, store: store)

        let suburb = try #require(try suburbRepository.find(id: suburbId))
        let result = try tuner.tune(suburb: suburb)
        #expect(result == .set(km: 5))

        let updated = try #require(try suburbRepository.find(id: suburbId))
        #expect(updated.nearbyRadiusKm == 5)
    }

    @Test func tuneIgnoresVenuesWithoutApprovedDeals() throws {
        let store = SQLStore.inMemory()
        let suburbRepository = SuburbRepository(store: store)
        let venueRepository = VenueRepository(store: store)
        let tuner = NearbyRadiusAutoTuner(
            venueRepository: venueRepository,
            suburbRepository: suburbRepository
        )

        let originLat = -33.8688
        let originLng = 151.2093
        let nearbyLng = originLng + (3.0 / (111.0 * cos(originLat * .pi / 180.0)))

        let suburbId = try insertSuburb(
            Suburb(name: "Origin", postcode: "2000", state: "NSW", lat: originLat, lng: originLng),
            store: store
        )
        let otherSuburbId = try insertSuburb(
            Suburb(name: "Other", postcode: "2010", state: "NSW", lat: originLat, lng: nearbyLng),
            store: store
        )
        _ = try insertVenue(
            name: "No Deals Pub",
            googleMapId: "nodeals-1",
            lat: originLat,
            lng: nearbyLng,
            suburbId: otherSuburbId,
            store: store
        )

        let suburb = try #require(try suburbRepository.find(id: suburbId))
        #expect(try tuner.tune(suburb: suburb) == .unchanged(.noDealsWithinMax))
        #expect(try suburbRepository.find(id: suburbId)?.nearbyRadiusKm == nil)
    }

    @Test func tuneIgnoresBrokenVenuesAndReportsNoneWithinMax() throws {
        let store = SQLStore.inMemory()
        let suburbRepository = SuburbRepository(store: store)
        let venueRepository = VenueRepository(store: store)
        let tuner = NearbyRadiusAutoTuner(
            venueRepository: venueRepository,
            suburbRepository: suburbRepository
        )

        let originLat = -33.8688
        let originLng = 151.2093
        let nearbyLng = originLng + (3.0 / (111.0 * cos(originLat * .pi / 180.0)))

        let suburbId = try insertSuburb(
            Suburb(name: "Origin", postcode: "2000", state: "NSW", lat: originLat, lng: originLng),
            store: store
        )
        let otherSuburbId = try insertSuburb(
            Suburb(name: "Other", postcode: "2010", state: "NSW", lat: originLat, lng: nearbyLng),
            store: store
        )
        let venueId = try insertVenue(
            name: "Broken Pub",
            googleMapId: "broken-1",
            lat: originLat,
            lng: nearbyLng,
            suburbId: otherSuburbId,
            status: .broken,
            store: store
        )
        try insertApprovedDeal(venueId: venueId, store: store)

        let suburb = try #require(try suburbRepository.find(id: suburbId))
        #expect(try tuner.tune(suburb: suburb) == .unchanged(.noDealsWithinMax))
        #expect(try suburbRepository.find(id: suburbId)?.nearbyRadiusKm == nil)
    }

    @Test func tuneRequiresCoordinates() throws {
        let store = SQLStore.inMemory()
        let suburbRepository = SuburbRepository(store: store)
        let venueRepository = VenueRepository(store: store)
        let tuner = NearbyRadiusAutoTuner(
            venueRepository: venueRepository,
            suburbRepository: suburbRepository
        )

        let suburbId = try insertSuburb(
            Suburb(name: "NoCoords", postcode: "2000", state: "NSW"),
            store: store
        )
        let suburb = try #require(try suburbRepository.find(id: suburbId))
        #expect(try tuner.tune(suburb: suburb) == .unchanged(.missingCoordinates))
    }

    @Test func minimumApprovedDealDistanceKmReturnsClosestOutsideDeal() throws {
        let store = SQLStore.inMemory()
        let venueRepository = VenueRepository(store: store)

        let originLat = -33.8688
        let originLng = 151.2093
        let nearKm = 4.0
        let farKm = 12.0
        let nearLng = originLng + (nearKm / (111.0 * cos(originLat * .pi / 180.0)))
        let farLng = originLng + (farKm / (111.0 * cos(originLat * .pi / 180.0)))

        let suburbId = try insertSuburb(
            Suburb(name: "Origin", postcode: "2000", state: "NSW", lat: originLat, lng: originLng),
            store: store
        )
        let otherId = try insertSuburb(
            Suburb(name: "Other", postcode: "2010", state: "NSW", lat: originLat, lng: nearLng),
            store: store
        )
        let nearVenueId = try insertVenue(
            name: "Near",
            googleMapId: "near",
            lat: originLat,
            lng: nearLng,
            suburbId: otherId,
            store: store
        )
        let farVenueId = try insertVenue(
            name: "Far",
            googleMapId: "far",
            lat: originLat,
            lng: farLng,
            suburbId: otherId,
            store: store
        )
        try insertApprovedDeal(venueId: nearVenueId, store: store)
        try insertApprovedDeal(venueId: farVenueId, store: store)

        let distance = try #require(
            try venueRepository.minimumApprovedDealDistanceKm(
                fromLat: originLat,
                lng: originLng,
                excludingSuburbId: suburbId,
                maxKm: 100
            )
        )
        #expect(abs(distance - nearKm) < 0.15)
    }

    @Test func findByRegionIdReturnsOnlyRegionSuburbs() throws {
        let store = SQLStore.inMemory()
        let suburbRepository = SuburbRepository(store: store)

        let regionA = try insertRegion(name: "Test Region A", store: store)
        let regionB = try insertRegion(name: "Test Region B", store: store)
        _ = try insertSuburb(
            Suburb(regionId: regionA, name: "A1", postcode: "1000", state: "NSW"),
            store: store
        )
        _ = try insertSuburb(
            Suburb(regionId: regionB, name: "B1", postcode: "2000", state: "NSW"),
            store: store
        )

        let suburbs = try suburbRepository.find(regionId: regionA)
        #expect(suburbs.count == 1)
        #expect(suburbs[0].name == "A1")
    }

    private func insertSuburb(_ suburb: Suburb, store: SQLStore) throws -> Int64 {
        try store.dbQueue.write { db in
            var mutable = suburb
            try mutable.insert(db)
            return try #require(mutable.id)
        }
    }

    private func insertRegion(name: String, store: SQLStore) throws -> Int64 {
        try store.dbQueue.write { db in
            let countryId = try #require(
                try Country.filter(Column("iso3") == Country.australia.iso3).fetchOne(db)?.id
            )
            var region = GeographicRegion(countryId: countryId, name: name)
            try region.insert(db)
            return try #require(region.id)
        }
    }

    @discardableResult
    private func insertVenue(
        name: String,
        googleMapId: String,
        lat: Double,
        lng: Double,
        suburbId: Int64,
        status: VenueStatus = .normal,
        store: SQLStore
    ) throws -> Int64 {
        try store.dbQueue.write { db in
            var venue = Venue(
                suburbId: suburbId,
                googleMapId: googleMapId,
                name: name,
                lat: lat,
                lng: lng,
                status: status,
                json: "{}"
            )
            try venue.insert(db)
            return try #require(venue.id)
        }
    }

    private func insertApprovedDeal(venueId: Int64, store: SQLStore) throws {
        try store.dbQueue.write { db in
            var deal = Deal(venueId: venueId, title: "Happy hour", status: .approved)
            try deal.insert(db)
        }
    }
}
