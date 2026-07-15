//Created by Alex Skorulis on 15/7/2026.

import Foundation
import Knit
import KnitMacros

@MainActor
@Observable
final class VenueHerosViewModel {

    enum State: Equatable {
        case idle
        case loading
        case failed(message: String)
        case processing(completed: Int, total: Int)
    }

    private(set) var state: State = .idle
    private(set) var venues: [Venue] = []
    private(set) var processFailures: [(name: String, message: String)] = []
    private(set) var lastProcessSummary: String?

    private let venueRepository: VenueRepository
    private let heroImageStore: VenueHeroImageStore

    @Resolvable<Resolver>
    init(
        venueRepository: VenueRepository,
        heroImageStore: VenueHeroImageStore
    ) {
        self.venueRepository = venueRepository
        self.heroImageStore = heroImageStore
    }

    var missingR2Count: Int {
        venues.filter { venue in
            guard let r2 = venue.heroR2Url else { return true }
            return r2.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count
    }

    var isProcessing: Bool {
        if case .processing = state { return true }
        return false
    }

    func load() {
        state = .loading
        do {
            venues = try venueRepository.all()
                .filter { venue in
                    guard let hero = venue.heroImage else { return false }
                    return !hero.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            state = .idle
        } catch {
            state = .failed(message: "Could not load hero images: \(error.localizedDescription)")
        }
    }

    func processImages() async {
        guard !isProcessing else { return }

        let pending = venues.filter { venue in
            guard let r2 = venue.heroR2Url else { return true }
            return r2.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard !pending.isEmpty else {
            lastProcessSummary = "All hero images already have an R2 URL."
            return
        }

        processFailures = []
        lastProcessSummary = nil
        var successCount = 0

        for (index, venue) in pending.enumerated() {
            state = .processing(completed: index, total: pending.count)
            do {
                if try await heroImageStore.uploadMissingR2IfNeeded(venue: venue) {
                    successCount += 1
                }
            } catch {
                processFailures.append((name: venue.name, message: error.localizedDescription))
            }
        }

        load()
        let failureCount = processFailures.count
        lastProcessSummary = "Uploaded \(successCount) of \(pending.count)."
            + (failureCount > 0 ? " \(failureCount) failed." : "")
        if case .failed = state {
            return
        }
        state = .idle
    }
}
