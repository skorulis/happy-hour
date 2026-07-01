//Created by Alex Skorulis on 1/7/2026.

import Foundation
import Knit
import KnitMacros

enum SuburbCrawlerError: LocalizedError {
    case missingAPIKey
    case missingSuburbID

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Configure a Google Places API key in Settings."
        case .missingSuburbID:
            return "This suburb has not been saved with a database ID."
        }
    }
}

@MainActor
final class SuburbCrawler {

    private let googlePlacesClient: GooglePlacesClient
    private let venueRepository: VenueRepository
    private let suburbRepository: SuburbRepository
    private let apiKeyStore: APIKeyStore

    @Resolvable<Resolver>
    init(
        googlePlacesClient: GooglePlacesClient,
        venueRepository: VenueRepository,
        suburbRepository: SuburbRepository,
        apiKeyStore: APIKeyStore
    ) {
        self.googlePlacesClient = googlePlacesClient
        self.venueRepository = venueRepository
        self.suburbRepository = suburbRepository
        self.apiKeyStore = apiKeyStore
    }

    func crawl(
        suburb: Suburb,
        progress: ProgressMonitor<SuburbCrawlResults> = .empty
    ) async throws -> SuburbCrawlResults {
        let apiKey = apiKeyStore.googlePlacesAPIKey
        guard !apiKey.isEmpty else {
            throw SuburbCrawlerError.missingAPIKey
        }
        guard let suburbId = suburb.id else {
            throw SuburbCrawlerError.missingSuburbID
        }

        let startedAt = Date()
        await progress("Searching Google Places…")

        let response = try await googlePlacesClient.searchTextAllPages(
            apiKey: apiKey,
            textQuery: Self.searchQuery(for: suburb),
            includedType: "bar",
            regionCode: "AU"
        )

        await progress("Saving \(response.places.count) venues…")

        let newCount = try venueRepository.upsert(places: response.places, suburbId: suburbId)
        try suburbRepository.updateLastCrawlDate(suburbId: suburbId, date: Date())

        let results = SuburbCrawlResults(
            venuesFound: response.places.count,
            newVenues: newCount,
            duration: Date().timeIntervalSince(startedAt)
        )
        await progress.completed(results: results)
        return results
    }

    nonisolated static func searchQuery(for suburb: Suburb) -> String {
        if let postcode = suburb.postcode?.trimmingCharacters(in: .whitespacesAndNewlines),
           !postcode.isEmpty
        {
            return "pubs in \(suburb.name) \(postcode)"
        }
        return "pubs in \(suburb.name)"
    }
}
