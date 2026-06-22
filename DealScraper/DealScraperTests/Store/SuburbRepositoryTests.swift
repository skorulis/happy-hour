//Created by Alex Skorulis on 22/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct SuburbRepositoryTests {

    @Test func upsertInsertsAndFindsSuburb() throws {
        let repository = SuburbRepository(store: SQLStore.inMemory())

        let suburbId = try repository.upsert(name: "Sydney", postcode: "2000")

        let found = try #require(try repository.find(name: "Sydney", postcode: "2000"))
        #expect(found.id == suburbId)
        #expect(found.name == "Sydney")
        #expect(found.postcode == "2000")
    }

    @Test func upsertReturnsExistingSuburbId() throws {
        let repository = SuburbRepository(store: SQLStore.inMemory())

        let firstId = try repository.upsert(name: "Newtown", postcode: "2042")
        let secondId = try repository.upsert(name: "Newtown", postcode: "2042")

        #expect(firstId == secondId)
    }
}
