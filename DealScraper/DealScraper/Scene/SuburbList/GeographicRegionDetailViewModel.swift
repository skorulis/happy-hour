// Created by Alexander Skorulis on 23/7/2026.

import ASKCoordinator
import Foundation
import Knit
import KnitMacros

@MainActor
@Observable
final class GeographicRegionDetailViewModel: CoordinatorViewModel {

    weak var coordinator: ASKCoordinator.Coordinator?

    let regionId: Int64
    private(set) var region: GeographicRegion?
    private(set) var suburbCount: Int = 0

    var canClearHeroImage: Bool {
        guard let region, region.id != nil else { return false }
        return region.heroImage?.isEmpty == false
    }

    private let geographicRegionRepository: GeographicRegionRepository
    private let heroImageStore: RegionHeroImageStore

    @Resolvable<Resolver>
    init(
        @Argument regionId: Int64,
        geographicRegionRepository: GeographicRegionRepository,
        heroImageStore: RegionHeroImageStore
    ) {
        self.regionId = regionId
        self.geographicRegionRepository = geographicRegionRepository
        self.heroImageStore = heroImageStore
        load()
    }

    func clearHeroImage() {
        guard canClearHeroImage else { return }

        do {
            try heroImageStore.clearHeroImage(regionId: regionId)
            refreshRegion()
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
            try await heroImageStore.setHeroImage(regionId: regionId, remoteURL: url)
            refreshRegion()
        } catch {
            print("Failed to set region hero image: \(error.localizedDescription)")
        }
    }

    private func load() {
        do {
            region = try geographicRegionRepository.find(id: regionId)
            suburbCount = try geographicRegionRepository.suburbCount(regionId: regionId)
        } catch {
            region = nil
            suburbCount = 0
        }
    }

    private func refreshRegion() {
        do {
            region = try geographicRegionRepository.find(id: regionId)
        } catch {
            // Keep the current UI state if refresh fails.
        }
    }
}
