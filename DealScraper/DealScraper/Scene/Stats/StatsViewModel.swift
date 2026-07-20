//Created by Alex Skorulis on 1/7/2026.

import Foundation
import Knit
import KnitMacros

@MainActor
@Observable
final class StatsViewModel {

    enum State: Equatable {
        case idle
        case failed(message: String)
    }

    private(set) var state: State = .idle

    private(set) var totalVenues: Int = 0
    private(set) var readyVenues: Int = 0
    private(set) var totalDealSources: Int = 0
    private(set) var acceptedDealSources: Int = 0
    private(set) var totalDeals: Int = 0
    private(set) var acceptedDeals: Int = 0
    private(set) var totalSuburbs: Int = 0
    private(set) var crawledSuburbs: Int = 0
    private(set) var suburbsWithVenues: Int = 0
    private(set) var suburbsWithDeals: Int = 0

    private let suburbRepository: SuburbRepository
    private let venueRepository: VenueRepository
    private let dealSourceRepository: DealSourceRepository
    private let dealRepository: DealRepository

    @Resolvable<Resolver>
    init(
        suburbRepository: SuburbRepository,
        venueRepository: VenueRepository,
        dealSourceRepository: DealSourceRepository,
        dealRepository: DealRepository
    ) {
        self.suburbRepository = suburbRepository
        self.venueRepository = venueRepository
        self.dealSourceRepository = dealSourceRepository
        self.dealRepository = dealRepository
    }

    func load() {
        do {
            let venues = try venueRepository.all()
            let dealCountsByVenueId = try dealRepository.countsByVenueId()

            totalVenues = venues.count
            readyVenues = venues.filter { venue in
                guard venue.status != .broken, let venueId = venue.id else { return false }
                return (dealCountsByVenueId[venueId] ?? 0) > 0
            }.count

            totalDealSources = try dealSourceRepository.count()
            acceptedDealSources = try dealSourceRepository.count(status: .approved)
            totalDeals = try dealRepository.count()
            acceptedDeals = try dealRepository.count(status: .approved)
            let suburbs = try suburbRepository.all()
            totalSuburbs = suburbs.count
            crawledSuburbs = suburbs.filter { $0.lastCrawlDate != nil }.count
            suburbsWithVenues = try venueRepository.countsBySuburbId().count
            suburbsWithDeals = try dealRepository.countDistinctSuburbsWithDeals()

            state = .idle
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }
}
