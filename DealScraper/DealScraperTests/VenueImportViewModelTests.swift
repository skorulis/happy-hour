//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Knit
import Testing
@testable import DealScraper

@MainActor
struct VenueImportViewModelTests {

    @Test func loadSavedVenuesReadsDatabase() throws {
        let store = SQLStore.inMemory()
        let repository = VenueRepository(store: store)
        let assembler = DealScraperAssembly.testing()

        let place = GooglePlace(
            id: "places/ChIJFromAPI",
            displayName: .init(text: "Harbour Pub", languageCode: "en"),
            location: .init(latitude: -33.8600, longitude: 151.2100),
            formattedAddress: "1 Circular Quay, Sydney",
            websiteUri: nil,
            types: ["bar"]
        )
        try repository.upsert(places: [place])

        let viewModel = VenueImportViewModel(
            venueRepository: repository,
            dealSourceRepository: DealSourceRepository(store: store),
            dealRepository: DealRepository(store: store)
        )

        viewModel.loadSavedVenues()

        #expect(viewModel.savedVenues.count == 1)
        #expect(viewModel.savedVenues.first?.name == "Harbour Pub")
    }
}
