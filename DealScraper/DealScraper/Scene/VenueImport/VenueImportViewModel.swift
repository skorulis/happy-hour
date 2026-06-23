//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Knit
import KnitMacros

@MainActor
@Observable
final class VenueImportViewModel {

    enum State: Equatable {
        case idle
        case failed(message: String)
    }

    private(set) var state: State = .idle
    private(set) var savedVenues: [Venue] = []
    private(set) var sourceCountsByVenueId: [Int64: Int] = [:]
    private(set) var dealCountsByVenueId: [Int64: Int] = [:]
    var searchText = ""
    var venueFilter: VenueFilter = .all
    var selectedGoogleMapId: String?

    enum VenueFilter: String, CaseIterable, Equatable {
        case all
        case crawl
        case extraction
        case ready

        var label: String {
            switch self {
            case .all:
                return "All"
            case .crawl:
                return "Crawl"
            case .extraction:
                return "Extraction"
            case .ready:
                return "Ready"
            }
        }
    }

    var filteredVenues: [Venue] {
        var venues = savedVenues

        switch venueFilter {
        case .all:
            break
        case .crawl:
            venues = venues.filter { sourceCount(for: $0) == 0 }
        case .extraction:
            venues = venues.filter { dealCount(for: $0) == 0 }
        case .ready:
            venues = venues.filter { dealCount(for: $0) > 0 }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return venues }
        return venues.filter { venue in
            venue.name.localizedCaseInsensitiveContains(query)
                || venue.json.localizedCaseInsensitiveContains(query)
        }
    }

    private let venueRepository: VenueRepository
    private let dealSourceRepository: DealSourceRepository
    private let dealRepository: DealRepository

    @Resolvable<Resolver>
    init(
        venueRepository: VenueRepository,
        dealSourceRepository: DealSourceRepository,
        dealRepository: DealRepository
    ) {
        self.venueRepository = venueRepository
        self.dealSourceRepository = dealSourceRepository
        self.dealRepository = dealRepository
    }

    func sourceCount(for venue: Venue) -> Int {
        guard let venueId = venue.id else { return 0 }
        return sourceCountsByVenueId[venueId] ?? 0
    }

    func dealCount(for venue: Venue) -> Int {
        guard let venueId = venue.id else { return 0 }
        return dealCountsByVenueId[venueId] ?? 0
    }

    func loadSavedVenues() {
        do {
            savedVenues = try venueRepository.all()
            sourceCountsByVenueId = try dealSourceRepository.countsByVenueId()
            dealCountsByVenueId = try dealRepository.countsByVenueId()
            if let selectedGoogleMapId,
               !savedVenues.contains(where: { $0.googleMapId == selectedGoogleMapId })
            {
                self.selectedGoogleMapId = nil
            }
            state = .idle
        } catch {
            state = .failed(message: "Could not load saved venues: \(error.localizedDescription)")
        }
    }
}
