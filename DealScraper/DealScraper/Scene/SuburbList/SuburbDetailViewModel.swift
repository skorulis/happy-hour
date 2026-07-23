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

    private let suburbRepository: SuburbRepository
    private let venueRepository: VenueRepository
    private let countryRepository: CountryRepository
    private let dealSourceRepository: DealSourceRepository
    private let dealRepository: DealRepository
    private let heroImageStore: SuburbHeroImageStore
    private let jobQueue: JobQueue

    @Resolvable<Resolver>
    init(
        @Argument suburbId: Int64,
        suburbRepository: SuburbRepository,
        venueRepository: VenueRepository,
        countryRepository: CountryRepository,
        dealSourceRepository: DealSourceRepository,
        dealRepository: DealRepository,
        heroImageStore: SuburbHeroImageStore,
        jobQueue: JobQueue
    ) {
        self.suburbId = suburbId
        self.suburbRepository = suburbRepository
        self.venueRepository = venueRepository
        self.countryRepository = countryRepository
        self.dealSourceRepository = dealSourceRepository
        self.dealRepository = dealRepository
        self.heroImageStore = heroImageStore
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
                countryName = nil
                sourceCountsByVenueId = [:]
                dealCountsByVenueId = [:]
                return
            }
            venues = try venueRepository.find(suburbId: suburbId)
            sourceCountsByVenueId = try dealSourceRepository.countsByVenueId()
            dealCountsByVenueId = try dealRepository.countsByVenueId()
            if let countryId = suburb.countryId {
                countryName = try countryRepository.find(id: countryId)?.name
            } else {
                countryName = nil
            }
        } catch {
            suburb = nil
            venues = []
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
}
