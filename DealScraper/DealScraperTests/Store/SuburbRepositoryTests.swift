//Created by Alex Skorulis on 22/6/2026.

import Foundation
import GRDB
import Testing
@testable import DealScraper

struct SuburbRepositoryTests {

    private func insertSuburb(
        _ suburb: Suburb,
        store: SQLStore
    ) throws -> Int64 {
        try store.dbQueue.write { db in
            var mutable = suburb
            try mutable.insert(db)
            return try #require(mutable.id)
        }
    }

    @Test func resolveReturnsExactMatchForNamePostcodeAndState() throws {
        let store = SQLStore.inMemory()
        let repository = SuburbRepository(store: store)
        let expectedId = try insertSuburb(
            Suburb(name: "Sydney", postcode: "2000", state: "NSW"),
            store: store
        )

        let resolvedId = try #require(
            try repository.resolve(name: "Sydney", postcode: "2000", state: "NSW")
        )

        #expect(resolvedId == expectedId)
    }

    @Test func resolveFallsBackToNameAndStateWhenPostcodeWrong() throws {
        let store = SQLStore.inMemory()
        let repository = SuburbRepository(store: store)
        let expectedId = try insertSuburb(
            Suburb(name: "Surry Hills", postcode: "2010", state: "NSW"),
            store: store
        )
        _ = try insertSuburb(
            Suburb(name: "Other Suburb", postcode: "9999", state: "NSW"),
            store: store
        )

        let resolvedId = try #require(
            try repository.resolve(name: "Surry Hills", postcode: "9999", state: "NSW")
        )

        #expect(resolvedId == expectedId)
    }

    @Test func resolveFallsBackToPostcodeWhenNameWrong() throws {
        let store = SQLStore.inMemory()
        let repository = SuburbRepository(store: store)
        let expectedId = try insertSuburb(
            Suburb(name: "Glebe", postcode: "2037", state: "NSW"),
            store: store
        )
        _ = try insertSuburb(
            Suburb(name: "Annandale", postcode: "2038", state: "NSW"),
            store: store
        )

        let resolvedId = try #require(
            try repository.resolve(name: "Wrong Name", postcode: "2037", state: "NSW")
        )

        #expect(resolvedId == expectedId)
    }

    @Test func resolveFallsBackToNameOnlyWhenStateAndPostcodeMissing() throws {
        let store = SQLStore.inMemory()
        let repository = SuburbRepository(store: store)
        let expectedId = try insertSuburb(
            Suburb(name: "Sydney", postcode: "2000", state: "NSW"),
            store: store
        )

        let resolvedId = try #require(
            try repository.resolve(name: "Sydney", postcode: nil, state: nil)
        )

        #expect(resolvedId == expectedId)
    }

    @Test func resolveReturnsNilWhenNoMatchFound() throws {
        let store = SQLStore.inMemory()
        let repository = SuburbRepository(store: store)

        let resolvedId = try repository.resolve(
            name: "Nowhere",
            postcode: "0000",
            state: "NSW"
        )

        #expect(resolvedId == nil)
    }

    @Test func findReturnsSuburbByNameAndPostcode() throws {
        let store = SQLStore.inMemory()
        let repository = SuburbRepository(store: store)
        let suburbId = try insertSuburb(
            Suburb(name: "Newtown", postcode: "2042", state: "NSW"),
            store: store
        )

        let found = try #require(try repository.find(name: "Newtown", postcode: "2042"))
        #expect(found.id == suburbId)
        #expect(found.name == "Newtown")
        #expect(found.postcode == "2042")
    }

    @Test func findReturnsSuburbByID() throws {
        let store = SQLStore.inMemory()
        let repository = SuburbRepository(store: store)
        let suburbId = try insertSuburb(
            Suburb(name: "Newtown", postcode: "2042", state: "NSW"),
            store: store
        )

        let found = try #require(try repository.find(id: suburbId))
        #expect(found.id == suburbId)
        #expect(found.name == "Newtown")
    }

    @Test func updateLastCrawlDatePersistsValue() throws {
        let store = SQLStore.inMemory()
        let repository = SuburbRepository(store: store)
        let suburbId = try insertSuburb(
            Suburb(name: "Newtown", postcode: "2042", state: "NSW"),
            store: store
        )
        let crawlDate = Date(timeIntervalSince1970: 1_700_000_000)

        try repository.updateLastCrawlDate(suburbId: suburbId, date: crawlDate)

        let found = try #require(try repository.find(id: suburbId))
        #expect(found.lastCrawlDate == crawlDate)
    }

    @Test func updateHeroImagePersistsURL() throws {
        let store = SQLStore.inMemory()
        let repository = SuburbRepository(store: store)
        let suburbId = try insertSuburb(
            Suburb(name: "Newtown", postcode: "2042", state: "NSW"),
            store: store
        )
        let heroURL = "https://example.com/suburb.jpg"

        try repository.updateHeroImage(suburbId: suburbId, url: heroURL)

        let found = try #require(try repository.find(id: suburbId))
        #expect(found.heroImage == heroURL)
        #expect(found.heroR2Url == nil)
    }

    @Test func updateHeroR2UrlPersistsURL() throws {
        let store = SQLStore.inMemory()
        let repository = SuburbRepository(store: store)
        let suburbId = try insertSuburb(
            Suburb(name: "Newtown", postcode: "2042", state: "NSW"),
            store: store
        )
        let r2URL = "https://images.duskroute.com/suburbs/\(suburbId).jpg"

        try repository.updateHeroR2Url(suburbId: suburbId, url: r2URL)

        let found = try #require(try repository.find(id: suburbId))
        #expect(found.heroR2Url == r2URL)
    }

    @Test func clearHeroImageFieldsClearsBoth() throws {
        let store = SQLStore.inMemory()
        let repository = SuburbRepository(store: store)
        let suburbId = try insertSuburb(
            Suburb(name: "Newtown", postcode: "2042", state: "NSW"),
            store: store
        )
        try repository.updateHeroImage(suburbId: suburbId, url: "https://example.com/suburb.jpg")
        try repository.updateHeroR2Url(
            suburbId: suburbId,
            url: "https://images.duskroute.com/suburbs/\(suburbId).jpg"
        )

        try repository.clearHeroImageFields(suburbId: suburbId)

        let found = try #require(try repository.find(id: suburbId))
        #expect(found.heroImage == nil)
        #expect(found.heroR2Url == nil)
    }

    @Test func isEligibleForCrawlRequiresPostcodeAndGreaterSydney() throws {
        let eligible = Suburb(
            name: "Newtown",
            postcode: "2042",
            state: "NSW",
            statisticArea: SuburbRepository.greaterSydneyStatisticArea
        )
        let missingPostcode = Suburb(
            name: "Newtown",
            postcode: nil,
            state: "NSW",
            statisticArea: SuburbRepository.greaterSydneyStatisticArea
        )
        let wrongArea = Suburb(
            name: "Newtown",
            postcode: "2042",
            state: "NSW",
            statisticArea: "Melbourne"
        )

        let excluded = Suburb(
            name: "Perrys Crossing",
            postcode: "2775",
            state: "NSW",
            statisticArea: SuburbRepository.greaterSydneyStatisticArea
        )

        #expect(SuburbRepository.isEligibleForCrawl(eligible))
        #expect(!SuburbRepository.isEligibleForCrawl(missingPostcode))
        #expect(!SuburbRepository.isEligibleForCrawl(wrongArea))
        #expect(!SuburbRepository.isEligibleForCrawl(excluded))
    }

    @Test func allEligibleForCrawlFiltersSuburbs() throws {
        let store = SQLStore.inMemory()
        let repository = SuburbRepository(store: store)
        _ = try insertSuburb(
            Suburb(name: "Newtown", postcode: "2042", state: "NSW", statisticArea: SuburbRepository.greaterSydneyStatisticArea),
            store: store
        )
        _ = try insertSuburb(
            Suburb(name: "No Postcode", postcode: nil, state: "NSW", statisticArea: SuburbRepository.greaterSydneyStatisticArea),
            store: store
        )
        _ = try insertSuburb(
            Suburb(name: "Melbourne", postcode: "3000", state: "VIC", statisticArea: "Melbourne"),
            store: store
        )

        let eligible = try repository.allEligibleForCrawl()

        #expect(eligible.count == 1)
        #expect(eligible[0].name == "Newtown")
    }
}
