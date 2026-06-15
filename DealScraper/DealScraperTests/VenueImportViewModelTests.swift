//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Knit
import Testing
@testable import DealScraper

@MainActor
struct VenueImportViewModelTests {

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

        let viewModel = VenueImportViewModel(
            googlePlacesClient: client,
            venueRepository: repository,
            apiKeyStore: apiKeyStore
        )

        viewModel.search()
        await waitForSearchCompletion(viewModel)

        #expect(viewModel.state == VenueImportViewModel.State.completed(importedCount: 1))
        #expect(viewModel.savedVenues.count == 1)
        #expect(viewModel.savedVenues.first?.name == "The Royal Pub")
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

        let viewModel = VenueImportViewModel(
            googlePlacesClient: client,
            venueRepository: repository,
            apiKeyStore: apiKeyStore
        )

        viewModel.search()
        await waitForSearchCompletion(viewModel)

        #expect(viewModel.state == VenueImportViewModel.State.failed(message: "Configure a Google Places API key in Settings."))
    }

    @Test func loadSavedVenuesReadsDatabase() throws {
        let store = SQLStore.inMemory()
        let repository = VenueRepository(store: store)
        let assembler = DealScraperAssembly.testing()
        let apiKeyStore = assembler.resolver.apiKeyStore()

        let place = GooglePlace(
            id: "places/ChIJFromAPI",
            displayName: .init(text: "Harbour Pub", languageCode: "en"),
            location: .init(latitude: -33.8600, longitude: 151.2100),
            formattedAddress: "1 Circular Quay, Sydney",
            types: ["bar"]
        )
        try repository.upsert(places: [place])

        let viewModel = VenueImportViewModel(
            googlePlacesClient: GooglePlacesClient(),
            venueRepository: repository,
            apiKeyStore: apiKeyStore
        )

        viewModel.loadSavedVenues()

        #expect(viewModel.savedVenues.count == 1)
        #expect(viewModel.savedVenues.first?.name == "Harbour Pub")
    }

    private func waitForSearchCompletion(_ viewModel: VenueImportViewModel) async {
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
