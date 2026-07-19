// Created by Alexander Skorulis on 19/7/2026.

import Foundation
import Knit
import KnitMacros

@MainActor
@Observable
final class SuburbDetailViewModel {

    let suburbId: Int64
    private(set) var suburb: Suburb?
    private(set) var venues: [Venue] = []
    private(set) var countryName: String?
    var actionMessage: String?

    var canClearHeroImage: Bool {
        guard let suburb, suburb.id != nil else { return false }
        return suburb.heroImage?.isEmpty == false
    }

    private let suburbRepository: SuburbRepository
    private let venueRepository: VenueRepository
    private let countryRepository: CountryRepository
    private let heroImageStore: SuburbHeroImageStore
    private let jobQueue: JobQueue

    @Resolvable<Resolver>
    init(
        @Argument suburbId: Int64,
        suburbRepository: SuburbRepository,
        venueRepository: VenueRepository,
        countryRepository: CountryRepository,
        heroImageStore: SuburbHeroImageStore,
        jobQueue: JobQueue
    ) {
        self.suburbId = suburbId
        self.suburbRepository = suburbRepository
        self.venueRepository = venueRepository
        self.countryRepository = countryRepository
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
            // Keep the current UI state if persistence fails.
        }
    }

    private func load() {
        do {
            suburb = try suburbRepository.find(id: suburbId)
            guard let suburb else {
                venues = []
                countryName = nil
                return
            }
            venues = try venueRepository.find(suburbId: suburbId)
            if let countryId = suburb.countryId {
                countryName = try countryRepository.find(id: countryId)?.name
            } else {
                countryName = nil
            }
        } catch {
            suburb = nil
            venues = []
            countryName = nil
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
