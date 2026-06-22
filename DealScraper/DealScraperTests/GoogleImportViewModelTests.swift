//Created by Alex Skorulis on 22/6/2026.

import Foundation
import Knit
import Testing
@testable import DealScraper

@MainActor
struct GoogleImportViewModelTests {

    private static let sampleResponse = """
    {
      "places": [
        {
          "id": "places/ChIJTest123",
          "displayName": {
            "text": "The Royal Pub",
            "languageCode": "en"
          },
          "location": {
            "latitude": -33.8688,
            "longitude": 151.2093
          },
          "formattedAddress": "123 George St, Sydney NSW 2000",
          "websiteUri": "https://theroyalpub.example.com",
          "types": ["bar", "point_of_interest"]
        }
      ],
      "nextPageToken": "next-page-token"
    }
    """

    @Test func searchTextImportsVenues() async {
        let store = SQLStore.inMemory()
        let repository = VenueRepository(store: store)
        let assembler = DealScraperAssembly.testing()
        let apiKeyStore = assembler.resolver.apiKeyStore()
        apiKeyStore.googlePlacesAPIKey = "google-test-key"

        let client = GooglePlacesClient { _ in
            let responseData = Self.sampleResponse.data(using: .utf8)!
            return try JSONDecoder().decode(GooglePlacesSearchResponse.self, from: responseData)
        }

        let viewModel = GoogleImportViewModel(
            googlePlacesClient: client,
            venueRepository: repository,
            apiKeyStore: apiKeyStore
        )

        viewModel.search()
        await waitForSearchCompletion(viewModel)

        #expect(viewModel.state == GoogleImportViewModel.State.completed(totalCount: 1, newCount: 1))
    }

    @Test func searchTextReportsExistingVenuesAsNotNew() async throws {
        let store = SQLStore.inMemory()
        let repository = VenueRepository(store: store)
        let assembler = DealScraperAssembly.testing()
        let apiKeyStore = assembler.resolver.apiKeyStore()
        apiKeyStore.googlePlacesAPIKey = "google-test-key"

        try repository.upsert(places: [
            GooglePlace(
                id: "places/ChIJTest123",
                displayName: .init(text: "The Royal Pub", languageCode: "en"),
                location: .init(latitude: -33.8688, longitude: 151.2093),
                formattedAddress: "123 George St, Sydney NSW 2000",
                websiteUri: "https://theroyalpub.example.com",
                types: ["bar"]
            ),
        ])

        let client = GooglePlacesClient { _ in
            let responseData = Self.sampleResponse.data(using: .utf8)!
            return try JSONDecoder().decode(GooglePlacesSearchResponse.self, from: responseData)
        }

        let viewModel = GoogleImportViewModel(
            googlePlacesClient: client,
            venueRepository: repository,
            apiKeyStore: apiKeyStore
        )

        viewModel.search()
        await waitForSearchCompletion(viewModel)

        #expect(viewModel.state == GoogleImportViewModel.State.completed(totalCount: 1, newCount: 0))
    }

    @Test func missingAPIKeyFails() async {
        let store = SQLStore.inMemory()
        let repository = VenueRepository(store: store)
        let assembler = DealScraperAssembly.testing()
        let apiKeyStore = assembler.resolver.apiKeyStore()
        apiKeyStore.googlePlacesAPIKey = ""

        let client = GooglePlacesClient { _ in
            Issue.record("Should not call API without key")
            let responseData = Self.sampleResponse.data(using: .utf8)!
            return try JSONDecoder().decode(GooglePlacesSearchResponse.self, from: responseData)
        }

        let viewModel = GoogleImportViewModel(
            googlePlacesClient: client,
            venueRepository: repository,
            apiKeyStore: apiKeyStore
        )

        viewModel.search()
        await waitForSearchCompletion(viewModel)

        #expect(viewModel.state == GoogleImportViewModel.State.failed(message: "Configure a Google Places API key in Settings."))
    }

    private func waitForSearchCompletion(_ viewModel: GoogleImportViewModel) async {
        for _ in 0..<50 {
            switch viewModel.state {
            case .searching, .idle:
                try? await Task.sleep(for: .milliseconds(20))
            case .completed, .failed:
                return
            }
        }
        Issue.record("Timed out waiting for search to complete")
    }
}
