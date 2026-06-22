//Created by Alex Skorulis on 22/6/2026.

import Foundation
import Knit
import KnitMacros

@MainActor
@Observable
final class JobQueueViewModel {

    private let jobQueue: JobQueue
    private let venueRepository: VenueRepository
    private var venueNames: [Int64: String] = [:]

    var jobs: [JobItem] {
        jobQueue.jobs.sorted { lhs, rhs in
            let lhsOrder = Self.sortOrder(for: lhs.status)
            let rhsOrder = Self.sortOrder(for: rhs.status)
            if lhsOrder != rhsOrder { return lhsOrder < rhsOrder }
            return lhs.id.uuidString > rhs.id.uuidString
        }
    }

    @Resolvable<Resolver>
    init(jobQueue: JobQueue, venueRepository: VenueRepository) {
        self.jobQueue = jobQueue
        self.venueRepository = venueRepository
    }

    func cancel(job: JobItem) {
        jobQueue.cancel(jobId: job.id)
    }

    func venueName(for venueId: Int64) -> String {
        if let cached = venueNames[venueId] {
            return cached
        }
        if let venue = try? venueRepository.find(id: venueId) {
            venueNames[venueId] = venue.name
            return venue.name
        }
        return "Venue #\(venueId)"
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
}
