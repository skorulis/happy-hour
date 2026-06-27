//Created by Alex Skorulis on 22/6/2026.

import ASKCore
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
      "nextPageToken": null
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

    @Test func searchTextPaginatesAndImportsAllPages() async {
        let store = SQLStore.inMemory()
        let repository = VenueRepository(store: store)
        let assembler = DealScraperAssembly.testing()
        let apiKeyStore = assembler.resolver.apiKeyStore()
        apiKeyStore.googlePlacesAPIKey = "google-test-key"

        let client = GooglePlacesClient { request in
            let httpRequest = try #require(request as? HTTPJSONRequest<GooglePlacesSearchResponse>)
            let body = try #require(httpRequest.body)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            let pageToken = json["pageToken"] as? String

            switch pageToken {
            case nil:
                return GooglePlacesSearchResponse(
                    places: [Self.samplePlace(id: "places/page-1", name: "Pub One")],
                    nextPageToken: "token-2"
                )
            case "token-2":
                return GooglePlacesSearchResponse(
                    places: [Self.samplePlace(id: "places/page-2", name: "Pub Two")],
                    nextPageToken: nil
                )
            default:
                Issue.record("Unexpected page token: \(pageToken ?? "nil")")
                return GooglePlacesSearchResponse(places: [], nextPageToken: nil)
            }
        }

        let viewModel = GoogleImportViewModel(
            googlePlacesClient: client,
            venueRepository: repository,
            apiKeyStore: apiKeyStore
        )

        viewModel.search()
        await waitForSearchCompletion(viewModel)

        #expect(viewModel.state == GoogleImportViewModel.State.completed(totalCount: 2, newCount: 2))
    }

    @Test func searchAreaImportsVenues() async {
        let store = SQLStore.inMemory()
        let repository = VenueRepository(store: store)
        let assembler = DealScraperAssembly.testing()
        let apiKeyStore = assembler.resolver.apiKeyStore()
        apiKeyStore.googlePlacesAPIKey = "google-test-key"

        let client = GooglePlacesClient { request in
            let httpRequest = try #require(request as? HTTPJSONRequest<GooglePlacesSearchResponse>)
            #expect(httpRequest.endpoint == "https://places.googleapis.com/v1/places:searchNearby")
            return GooglePlacesSearchResponse(
                places: [Self.samplePlace(id: "places/area-1", name: "Area Pub")],
                nextPageToken: nil
            )
        }

        let viewModel = GoogleImportViewModel(
            googlePlacesClient: client,
            venueRepository: repository,
            apiKeyStore: apiKeyStore
        )
        viewModel.searchMode = .area
        viewModel.southWestLatitude = "-33.870"
        viewModel.southWestLongitude = "151.205"
        viewModel.northEastLatitude = "-33.868"
        viewModel.northEastLongitude = "151.210"
        viewModel.cellRadiusMeters = "500"

        viewModel.search()
        await waitForSearchCompletion(viewModel)

        if case let .completed(totalCount, newCount, saturatedCellCount, apiCallCount) = viewModel.state {
            #expect(totalCount == 1)
            #expect(newCount == 1)
            #expect(saturatedCellCount == 0)
            #expect(apiCallCount >= 1)
        } else {
            Issue.record("Expected completed state, got \(viewModel.state)")
        }
    }

    private static func samplePlace(id: String, name: String) -> GooglePlace {
        GooglePlace(
            id: id,
            displayName: .init(text: name, languageCode: "en"),
            location: .init(latitude: -33.8688, longitude: 151.2093),
            formattedAddress: "123 George St, Sydney NSW 2000",
            websiteUri: "https://example.com",
            types: ["bar"]
        )
    }

    private func waitForSearchCompletion(_ viewModel: GoogleImportViewModel) async {
        for _ in 0..<500 {
            switch viewModel.state {
            case .searching, .idle, .sweeping:
                try? await Task.sleep(for: .milliseconds(20))
            case .completed, .failed:
                return
            }
        }
        Issue.record("Timed out waiting for search to complete")
    }
}
