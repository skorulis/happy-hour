//Created by Alex Skorulis on 17/6/2026.

import Foundation
import Knit
import Testing
@testable import DealScraper

@MainActor
struct VenueDealExtractionServiceTests {

    @Test func throwsWhenVenueHasNoID() async {
        let assembler = DealScraperAssembly.testing()
        let service = assembler.resolver.venueDealExtractionService()
        let venue = Venue(
            googleMapId: "places/test",
            name: "Test Pub",
            lat: 0,
            lng: 0,
            json: "{}"
        )

        do {
            _ = try await service.extractDeals(for: venue, provider: .cursor, model: "composer-2.5")
            Issue.record("Expected missingVenueID error")
        } catch let error as VenueDealExtractionServiceError {
            #expect(error == .missingVenueID)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func throwsWhenNoApprovedSources() async throws {
        let assembler = DealScraperAssembly.testing()
        let venueRepository = assembler.resolver.venueRepository()
        let service = assembler.resolver.venueDealExtractionService()

        try venueRepository.upsert(Venue(
            googleMapId: "places/test",
            name: "Test Pub",
            lat: 0,
            lng: 0,
            json: "{}"
        ))

        var venue = try #require(try venueRepository.find(googleMapId: "places/test"))

        do {
            _ = try await service.extractDeals(for: venue, provider: .cursor, model: "composer-2.5")
            Issue.record("Expected noApprovedSources error")
        } catch let error as VenueDealExtractionServiceError {
            #expect(error == .noApprovedSources)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
