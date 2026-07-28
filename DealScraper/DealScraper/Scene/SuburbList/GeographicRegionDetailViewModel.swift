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
    private(set) var crawledSuburbCount: Int = 0
    private(set) var venueCount: Int = 0
    private(set) var nonBrokenVenueCount: Int = 0
    private(set) var crawledVenueCount: Int = 0
    private(set) var venuesWithApprovedSourcesCount: Int = 0
    private(set) var extractedVenueCount: Int = 0
    private(set) var sourceCount: Int = 0
    private(set) var dealCount: Int = 0
    private(set) var isAutoTuningNearbyRadius = false
    var actionMessage: String?

    var canClearHeroImage: Bool {
        guard let region, region.id != nil else { return false }
        return region.heroImage?.isEmpty == false
    }

    private let geographicRegionRepository: GeographicRegionRepository
    private let suburbRepository: SuburbRepository
    private let nearbyRadiusAutoTuner: NearbyRadiusAutoTuner
    private let heroImageStore: RegionHeroImageStore

    @Resolvable<Resolver>
    init(
        @Argument regionId: Int64,
        geographicRegionRepository: GeographicRegionRepository,
        suburbRepository: SuburbRepository,
        nearbyRadiusAutoTuner: NearbyRadiusAutoTuner,
        heroImageStore: RegionHeroImageStore
    ) {
        self.regionId = regionId
        self.geographicRegionRepository = geographicRegionRepository
        self.suburbRepository = suburbRepository
        self.nearbyRadiusAutoTuner = nearbyRadiusAutoTuner
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

    func autoTuneNearbyRadiusForAllSuburbs() {
        guard !isAutoTuningNearbyRadius else { return }

        isAutoTuningNearbyRadius = true
        actionMessage = "Auto-tuning nearby radius…"

        Task {
            await Task.yield()
            do {
                let suburbs = try suburbRepository.find(regionId: regionId)
                let summary = try nearbyRadiusAutoTuner.tuneAll(suburbs: suburbs)
                actionMessage = Self.summaryMessage(summary)
            } catch {
                actionMessage = "Failed to auto-tune nearby radius."
            }
            isAutoTuningNearbyRadius = false
        }
    }

    private static func summaryMessage(_ summary: NearbyRadiusTuneSummary) -> String {
        var parts: [String] = ["Set \(summary.setCount)"]
        if summary.clearedCount > 0 {
            parts.append("default ok \(summary.clearedCount)")
        }
        if summary.missingCoordinatesCount > 0 {
            parts.append("skipped \(summary.missingCoordinatesCount)")
        }
        if summary.noneFoundCount > 0 {
            parts.append("none found \(summary.noneFoundCount)")
        }
        if summary.missingSuburbIdCount > 0 {
            parts.append("invalid \(summary.missingSuburbIdCount)")
        }
        return parts.joined(separator: ", ") + "."
    }

    private func load() {
        do {
            region = try geographicRegionRepository.find(id: regionId)
            suburbCount = try geographicRegionRepository.suburbCount(regionId: regionId)
            crawledSuburbCount = try geographicRegionRepository.crawledSuburbCount(regionId: regionId)
            venueCount = try geographicRegionRepository.venueCount(regionId: regionId)
            nonBrokenVenueCount = try geographicRegionRepository.nonBrokenVenueCount(regionId: regionId)
            crawledVenueCount = try geographicRegionRepository.crawledVenueCount(regionId: regionId)
            venuesWithApprovedSourcesCount = try geographicRegionRepository.venuesWithApprovedSourcesCount(regionId: regionId)
            extractedVenueCount = try geographicRegionRepository.extractedVenueCount(regionId: regionId)
            sourceCount = try geographicRegionRepository.dealSourceCount(regionId: regionId)
            dealCount = try geographicRegionRepository.dealCount(regionId: regionId)
        } catch {
            region = nil
            suburbCount = 0
            crawledSuburbCount = 0
            venueCount = 0
            nonBrokenVenueCount = 0
            crawledVenueCount = 0
            venuesWithApprovedSourcesCount = 0
            extractedVenueCount = 0
            sourceCount = 0
            dealCount = 0
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
