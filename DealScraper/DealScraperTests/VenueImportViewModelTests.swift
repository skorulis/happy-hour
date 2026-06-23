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

    @Test func venueFilterShowsVenuesMatchingPipelineStage() throws {
        let store = SQLStore.inMemory()
        let venueRepository = VenueRepository(store: store)
        let dealSourceRepository = DealSourceRepository(store: store)
        let dealRepository = DealRepository(store: store)

        try venueRepository.upsert(Venue(
            googleMapId: "places/no-sources",
            name: "Needs Crawl",
            lat: 0,
            lng: 0,
            json: "{}"
        ))
        try venueRepository.upsert(Venue(
            googleMapId: "places/no-deals",
            name: "Needs Extraction",
            lat: 0,
            lng: 0,
            json: "{}"
        ))
        try venueRepository.upsert(Venue(
            googleMapId: "places/ready",
            name: "Ready Pub",
            lat: 0,
            lng: 0,
            json: "{}"
        ))

        let extractionVenueId = try #require(try venueRepository.find(googleMapId: "places/no-deals")?.id)
        let readyVenueId = try #require(try venueRepository.find(googleMapId: "places/ready")?.id)

        try dealSourceRepository.upsert(
            sources: [
                DealSource(
                    venueId: extractionVenueId,
                    url: "https://example.com/menu.pdf",
                    type: .pdf
                ),
            ],
            forVenueId: extractionVenueId
        )
        try dealSourceRepository.upsert(
            sources: [
                DealSource(
                    venueId: readyVenueId,
                    url: "https://example.com/specials",
                    type: .webpage
                ),
            ],
            forVenueId: readyVenueId
        )

        let deal = Deal(
            venueId: readyVenueId,
            title: "Happy Hour",
            details: "$8 wines"
        )
        let schedules = [
            DealSchedule(dealId: 0, dayOfWeek: 6, startMinute: 960, endMinute: 1_080),
        ]
        try dealRepository.replaceAll(
            venueId: readyVenueId,
            deals: [DealWithSchedules(deal: deal, schedules: schedules)]
        )

        let viewModel = VenueImportViewModel(
            venueRepository: venueRepository,
            dealSourceRepository: dealSourceRepository,
            dealRepository: dealRepository
        )
        viewModel.loadSavedVenues()

        viewModel.venueFilter = .all
        #expect(viewModel.filteredVenues.map(\.name) == ["Needs Crawl", "Needs Extraction", "Ready Pub"])

        viewModel.venueFilter = .crawl
        #expect(viewModel.filteredVenues.map(\.name) == ["Needs Crawl"])

        viewModel.venueFilter = .extraction
        #expect(viewModel.filteredVenues.map(\.name) == ["Needs Crawl", "Needs Extraction"])

        viewModel.venueFilter = .ready
        #expect(viewModel.filteredVenues.map(\.name) == ["Ready Pub"])
    }
}
