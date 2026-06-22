//Created by Alex Skorulis on 22/6/2026.

import Foundation

enum JobResult: Equatable, Sendable {
    case crawl(VenueCrawlResults)
    case extract(VenueDealExtractionResults)
}

enum JobStatus: Equatable, Sendable {
    case pending
    case running(progress: String)
    case completed(JobResult)
    case failed(message: String)
    case cancelled

    var isActive: Bool {
        switch self {
        case .pending, .running:
            return true
        case .completed, .failed, .cancelled:
            return false
        }
    }
}

struct JobItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let venueId: Int64
    let type: JobType
    var status: JobStatus

    init(
        id: UUID = UUID(),
        venueId: Int64,
        type: JobType,
        status: JobStatus = .pending
    ) {
        self.id = id
        self.venueId = venueId
        self.type = type
        self.status = status
    }
}
