//Created by Alex Skorulis on 22/6/2026.

import Foundation

enum JobSubject: Equatable, Sendable {
    case venue(Int64)
    case suburb(Int64)
}

enum JobResult: Equatable, Sendable {
    case crawl(VenueCrawlResults)
    case extract(VenueDealExtractionResults)
    case crawlSuburb(SuburbCrawlResults)
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
    let subject: JobSubject
    let type: JobType
    var status: JobStatus
    var startDate: Date?

    var venueId: Int64? {
        if case let .venue(id) = subject { return id }
        return nil
    }

    var suburbId: Int64? {
        if case let .suburb(id) = subject { return id }
        return nil
    }

    init(
        id: UUID = UUID(),
        venueId: Int64,
        type: JobType,
        status: JobStatus = .pending,
        startDate: Date? = nil
    ) {
        self.id = id
        self.subject = .venue(venueId)
        self.type = type
        self.status = status
        self.startDate = startDate
    }

    init(
        id: UUID = UUID(),
        suburbId: Int64,
        type: JobType,
        status: JobStatus = .pending,
        startDate: Date? = nil
    ) {
        self.id = id
        self.subject = .suburb(suburbId)
        self.type = type
        self.status = status
        self.startDate = startDate
    }
}
