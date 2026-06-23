//Created by Alex Skorulis on 22/6/2026.

import ASKCoordinator
import Foundation
import Knit
import KnitMacros

@MainActor
@Observable
final class JobQueueViewModel: CoordinatorViewModel {
    weak var coordinator: ASKCoordinator.Coordinator?
    
    private let jobQueue: JobQueue
    private let venueRepository: VenueRepository
    private let dealSourceRepository: DealSourceRepository
    private let dealRepository: DealRepository
    private var venueNames: [Int64: String] = [:]
    private var venueGoogleMapIds: [Int64: String] = [:]

    var actionMessage: String?

    var jobs: [JobItem] {
        jobQueue.jobs.sorted { lhs, rhs in
            let lhsOrder = Self.sortOrder(for: lhs.status)
            let rhsOrder = Self.sortOrder(for: rhs.status)
            if lhsOrder != rhsOrder { return lhsOrder < rhsOrder }
            return lhs.id.uuidString > rhs.id.uuidString
        }
    }

    @Resolvable<Resolver>
    init(
        jobQueue: JobQueue,
        venueRepository: VenueRepository,
        dealSourceRepository: DealSourceRepository,
        dealRepository: DealRepository
    ) {
        self.jobQueue = jobQueue
        self.venueRepository = venueRepository
        self.dealSourceRepository = dealSourceRepository
        self.dealRepository = dealRepository
    }

    func crawlNext() {
        guard let venueId = nextVenueIdForCrawl() else {
            actionMessage = "No venues without sources found."
            return
        }

        guard jobQueue.enqueue(venueId: venueId, type: .crawlWebsite) != nil else {
            actionMessage = "A crawl is already queued for \(venueName(for: venueId))."
            return
        }

        actionMessage = "Queued crawl for \(venueName(for: venueId))."
    }

    func extractNext() {
        guard let venueId = nextVenueIdForExtraction() else {
            actionMessage = "No venues ready for extraction found."
            return
        }

        guard jobQueue.enqueue(venueId: venueId, type: .extractDeals) != nil else {
            actionMessage = "Extraction is already queued for \(venueName(for: venueId))."
            return
        }

        actionMessage = "Queued extraction for \(venueName(for: venueId))."
    }

    func cancel(job: JobItem) {
        jobQueue.cancel(jobId: job.id)
    }

    func venueName(for venueId: Int64) -> String {
        if let cached = venueNames[venueId] {
            return cached
        }
        if let venue = try? venueRepository.find(id: venueId) {
            cacheVenue(venue)
            return venue.name
        }
        return "Venue #\(venueId)"
    }

    func googleMapId(for venueId: Int64) -> String? {
        if let cached = venueGoogleMapIds[venueId] {
            return cached
        }
        if let venue = try? venueRepository.find(id: venueId) {
            cacheVenue(venue)
            return venue.googleMapId
        }
        return nil
    }

    private func cacheVenue(_ venue: Venue) {
        guard let venueId = venue.id else { return }
        venueNames[venueId] = venue.name
        venueGoogleMapIds[venueId] = venue.googleMapId
    }

    func canCancel(_ job: JobItem) -> Bool {
        switch job.status {
        case .pending, .running:
            return true
        case .completed, .failed, .cancelled:
            return false
        }
    }

    private static func sortOrder(for status: JobStatus) -> Int {
        switch status {
        case .running:
            return 0
        case .pending:
            return 1
        case .completed, .failed, .cancelled:
            return 2
        }
    }

    private func nextVenueIdForCrawl() -> Int64? {
        guard let venues = try? venueRepository.all(),
              let sourceCounts = try? dealSourceRepository.countsByVenueId()
        else { return nil }

        return venues
            .sorted { ($0.id ?? .max) < ($1.id ?? .max) }
            .first { venue in
                guard let venueId = venue.id,
                      venue.websiteUri != nil
                else { return false }

                let sourceCount = sourceCounts[venueId] ?? 0
                return sourceCount == 0
                    && !jobQueue.isJobActive(venueId: venueId, type: .crawlWebsite)
            }?
            .id
    }

    private func nextVenueIdForExtraction() -> Int64? {
        guard let venues = try? venueRepository.all(),
              let dealCounts = try? dealRepository.countsByVenueId()
        else { return nil }

        return venues
            .sorted { ($0.id ?? .max) < ($1.id ?? .max) }
            .first { venue in
                guard let venueId = venue.id else { return false }
                guard (dealCounts[venueId] ?? 0) == 0 else { return false }
                guard !jobQueue.isJobActive(venueId: venueId, type: .extractDeals) else { return false }

                guard let sources = try? dealSourceRepository.find(venueId: venueId),
                      !sources.isEmpty
                else { return false }

                let hasApproved = sources.contains { $0.status == .approved }
                let allReviewed = sources.allSatisfy {
                    $0.status == .approved || $0.status == .rejected
                }
                return hasApproved && allReviewed
            }?
            .id
    }
}
