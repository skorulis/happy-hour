// Created by Alexander Skorulis on 19/7/2026.

import ASKCoordinator
import Foundation
import Knit
import KnitMacros

@MainActor
@Observable
final class SuburbDetailViewModel: CoordinatorViewModel {

    weak var coordinator: ASKCoordinator.Coordinator?

    let suburbId: Int64
    private(set) var suburb: Suburb?
    private(set) var venues: [Venue] = []
    private(set) var regionName: String?
    private(set) var countryName: String?
    private(set) var sourceCountsByVenueId: [Int64: Int] = [:]
    private(set) var dealCountsByVenueId: [Int64: Int] = [:]
    var actionMessage: String?

    var canClearHeroImage: Bool {
        guard let suburb, suburb.id != nil else { return false }
        return suburb.heroImage?.isEmpty == false
    }

    var venuesWithHeroImages: [Venue] {
        venues.filter { venue in
            guard let hero = venue.heroImage?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                return false
            }
            return !hero.isEmpty
        }
    }

    var totalSourceCount: Int {
        venues.reduce(0) { $0 + sourceCount(for: $1) }
    }

    var totalDealCount: Int {
        venues.reduce(0) { $0 + dealCount(for: $1) }
    }

    private let suburbRepository: SuburbRepository
    private let venueRepository: VenueRepository
    private let geographicRegionRepository: GeographicRegionRepository
    private let countryRepository: CountryRepository
    private let dealSourceRepository: DealSourceRepository
    private let dealRepository: DealRepository
    private let heroImageStore: SuburbHeroImageStore
    private let nearbyRadiusAutoTuner: NearbyRadiusAutoTuner
    private let jobQueue: JobQueue

    @Resolvable<Resolver>
    init(
        @Argument suburbId: Int64,
        suburbRepository: SuburbRepository,
        venueRepository: VenueRepository,
        geographicRegionRepository: GeographicRegionRepository,
        countryRepository: CountryRepository,
        dealSourceRepository: DealSourceRepository,
        dealRepository: DealRepository,
        heroImageStore: SuburbHeroImageStore,
        nearbyRadiusAutoTuner: NearbyRadiusAutoTuner,
        jobQueue: JobQueue
    ) {
        self.suburbId = suburbId
        self.suburbRepository = suburbRepository
        self.venueRepository = venueRepository
        self.geographicRegionRepository = geographicRegionRepository
        self.countryRepository = countryRepository
        self.dealSourceRepository = dealSourceRepository
        self.dealRepository = dealRepository
        self.heroImageStore = heroImageStore
        self.nearbyRadiusAutoTuner = nearbyRadiusAutoTuner
        self.jobQueue = jobQueue
        load()
    }

    func crawl() {
        guard let suburb else {
            actionMessage = "Suburb not found."
            return
        }

        let name = SuburbListViewModel.displayName(for: suburb)
        guard jobQueue.enqueue(suburbId: suburbId, type: .crawlSuburb) != nil else {
            actionMessage = "A suburb crawl is already queued for \(name)."
            return
        }

        actionMessage = "Queued suburb crawl for \(name)."
    }

    func crawlAllWebsites() {
        let crawlableVenues = venues.compactMap { venue -> Int64? in
            guard venue.websiteUri != nil, let venueId = venue.id else { return nil }
            return venueId
        }

        guard !crawlableVenues.isEmpty else {
            actionMessage = venues.isEmpty
                ? "No venues to crawl."
                : "No venues with websites to crawl."
            return
        }

        var queuedCount = 0
        var alreadyQueuedCount = 0
        for venueId in crawlableVenues {
            if jobQueue.enqueue(venueId: venueId, type: .crawlWebsite) != nil {
                queuedCount += 1
            } else {
                alreadyQueuedCount += 1
            }
        }

        if queuedCount == 0 {
            actionMessage = "All \(alreadyQueuedCount) venue website crawl\(alreadyQueuedCount == 1 ? "" : "s") already queued."
        } else if alreadyQueuedCount == 0 {
            actionMessage = "Queued website crawl for \(queuedCount) venue\(queuedCount == 1 ? "" : "s")."
        } else {
            actionMessage = "Queued website crawl for \(queuedCount) venue\(queuedCount == 1 ? "" : "s") (\(alreadyQueuedCount) already queued)."
        }
    }

    func clearHeroImage() {
        guard canClearHeroImage else { return }

        do {
            try heroImageStore.clearHeroImage(suburbId: suburbId)
            refreshSuburb()
        } catch {
            // Keep the current UI state if persistence fails.
        }
    }

    func setHeroImage(urlString: String) async {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let url = URL(string: trimmed),
              url.scheme != nil
        else {
            return
        }

        do {
            try await heroImageStore.setHeroImage(suburbId: suburbId, remoteURL: url)
            refreshSuburb()
        } catch {
            print("Failed to set suburb hero image: \(error.localizedDescription)")
        }
    }

    func setNearbyRadiusKm(_ value: Double?) {
        do {
            try suburbRepository.updateNearbyRadiusKm(
                suburbId: suburbId,
                nearbyRadiusKm: value
            )
            refreshSuburb()
            if let value {
                actionMessage = "Nearby radius set to \(formatKm(value)) km."
            } else {
                actionMessage = "Nearby radius cleared (using area formula)."
            }
        } catch {
            actionMessage = "Failed to update nearby radius."
        }
    }

    func autoTuneNearbyRadius() {
        guard let suburb else {
            actionMessage = "Suburb not found."
            return
        }

        do {
            switch try nearbyRadiusAutoTuner.tune(suburb: suburb) {
            case .set(let km):
                refreshSuburb()
                actionMessage = "Nearby radius set to \(formatKm(km)) km."
            case .cleared:
                refreshSuburb()
                actionMessage = "Default radius is enough; nearby radius left blank."
            case .unchanged(.missingCoordinates):
                actionMessage = "Suburb is missing coordinates."
            case .unchanged(.noVenuesWithinMax):
                actionMessage = "No nearby venues within \(formatKm(NearbyRadiusAutoTuner.maxLadderKm)) km."
            case .unchanged(.missingSuburbId):
                actionMessage = "Suburb not found."
            }
        } catch {
            actionMessage = "Failed to auto-tune nearby radius."
        }
    }

    func sourceCount(for venue: Venue) -> Int {
        guard let venueId = venue.id else { return 0 }
        return sourceCountsByVenueId[venueId] ?? 0
    }

    func dealCount(for venue: Venue) -> Int {
        guard let venueId = venue.id else { return 0 }
        return dealCountsByVenueId[venueId] ?? 0
    }

    func openVenueDetails(googleMapId: String) {
        coordinator?.push(MainPath.venueDetails(googleMapId))
    }

    private func load() {
        do {
            suburb = try suburbRepository.find(id: suburbId)
            guard let suburb else {
                venues = []
                regionName = nil
                countryName = nil
                sourceCountsByVenueId = [:]
                dealCountsByVenueId = [:]
                return
            }
            venues = try venueRepository.find(suburbId: suburbId)
            sourceCountsByVenueId = try dealSourceRepository.countsByVenueId()
            dealCountsByVenueId = try dealRepository.countsByVenueId()
            if let regionId = suburb.regionId {
                regionName = try geographicRegionRepository.find(id: regionId)?.name
            } else {
                regionName = nil
            }
            if let countryId = suburb.countryId {
                countryName = try countryRepository.find(id: countryId)?.name
            } else {
                countryName = nil
            }
        } catch {
            suburb = nil
            venues = []
            regionName = nil
            countryName = nil
            sourceCountsByVenueId = [:]
            dealCountsByVenueId = [:]
        }
    }

    private func refreshSuburb() {
        do {
            suburb = try suburbRepository.find(id: suburbId)
        } catch {
            // Keep the current UI state if refresh fails.
        }
    }

    private func formatKm(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%g", value)
    }
}
