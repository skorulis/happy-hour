//Created by Alex Skorulis on 22/6/2026.

import Foundation
import Testing
@testable import DealScraper

@MainActor
@Suite(.serialized)
struct JobQueueTests {

    private func makeVenue(id: Int64 = 1) -> Venue {
        Venue(
            id: id,
            googleMapId: "places/test",
            name: "Test Pub",
            lat: -33.86,
            lng: 151.20,
            websiteUri: "https://example.com",
            json: "{}"
        )
    }

    private func makeRepository(with venue: Venue) -> VenueRepository {
        let store = SQLStore.inMemory()
        let repository = VenueRepository(store: store)
        try! repository.upsert(venue)
        return repository
    }

    @Test func enqueueCompletesAllJobsForSameVenue() async {
        let venue = makeVenue()
        let repository = makeRepository(with: venue)

        let crawler = FakeVenueWebsiteCrawler { venue, progress in
            await progress("Crawling…")
            return VenueCrawlResults(dealsFound: 1, visitedPages: [], imagesAnalyzed: 0, duration: 0.1)
        }
        let extractor = FakeVenueDealExtractor { venue, progress in
            await progress("Extracting…")
            return VenueDealExtractionResults(
                dealsFoundBeforeCondensing: 1,
                dealsFound: 1,
                duration: 0.1,
                errorCount: 0
            )
        }

        let jobQueue = JobQueue(
            venueRepository: repository,
            venueWebsiteCrawler: crawler,
            venueDealExtractionService: extractor
        )

        _ = jobQueue.enqueue(venueId: 1, type: .crawlWebsite)
        _ = jobQueue.enqueue(venueId: 1, type: .extractDeals)

        await waitForJobs(toFinish: 2, in: jobQueue)

        #expect(jobQueue.jobs.count == 2)
        #expect(jobQueue.jobs.allSatisfy { job in
            if case .completed = job.status { return true }
            return false
        })
    }

    @Test func enqueueRunsUpToMaxConcurrentJobs() async {
        let repository = makeRepository(with: makeVenue())
        for id in 2...3 {
            try! repository.upsert(makeVenue(id: Int64(id)))
        }

        let crawler = FakeVenueWebsiteCrawler { _, _ in
            try await Task.sleep(for: .milliseconds(100))
            return VenueCrawlResults(dealsFound: 0, visitedPages: [], imagesAnalyzed: 0, duration: 0)
        }

        let jobQueue = JobQueue(
            venueRepository: repository,
            venueWebsiteCrawler: crawler,
            venueDealExtractionService: FakeVenueDealExtractor { _, _ in
                VenueDealExtractionResults(dealsFoundBeforeCondensing: 0, dealsFound: 0, duration: 0, errorCount: 0)
            }
        )

        _ = jobQueue.enqueue(venueId: 1, type: .crawlWebsite)
        _ = jobQueue.enqueue(venueId: 2, type: .crawlWebsite)
        _ = jobQueue.enqueue(venueId: 3, type: .crawlWebsite)

        let runningCount = jobQueue.jobs.filter { job in
            if case .running = job.status { return true }
            return false
        }.count
        let pendingCount = jobQueue.jobs.filter { job in
            if case .pending = job.status { return true }
            return false
        }.count

        #expect(runningCount == 2)
        #expect(pendingCount == 1)

        await waitForJobs(toFinish: 3, in: jobQueue)
    }

    @Test func duplicateEnqueueIsRejected() async {
        let venue = makeVenue()
        let repository = makeRepository(with: venue)
        let crawler = FakeVenueWebsiteCrawler { _, _ in
            try await Task.sleep(for: .milliseconds(100))
            return VenueCrawlResults(dealsFound: 0, visitedPages: [], imagesAnalyzed: 0, duration: 0)
        }

        let jobQueue = JobQueue(
            venueRepository: repository,
            venueWebsiteCrawler: crawler,
            venueDealExtractionService: FakeVenueDealExtractor { _, _ in
                VenueDealExtractionResults(dealsFoundBeforeCondensing: 0, dealsFound: 0, duration: 0, errorCount: 0)
            }
        )

        let first = jobQueue.enqueue(venueId: 1, type: .crawlWebsite)
        let second = jobQueue.enqueue(venueId: 1, type: .crawlWebsite)

        #expect(first != nil)
        #expect(second == nil)
        #expect(jobQueue.jobs.count == 1)

        await waitForJobs(toFinish: 1, in: jobQueue)
    }

    @Test func cancelPendingJobMarksCancelled() async {
        let repository = makeRepository(with: makeVenue())
        for id in 2...3 {
            try! repository.upsert(makeVenue(id: Int64(id)))
        }

        let crawler = FakeVenueWebsiteCrawler { _, _ in
            try await Task.sleep(for: .milliseconds(200))
            return VenueCrawlResults(dealsFound: 0, visitedPages: [], imagesAnalyzed: 0, duration: 0)
        }

        let jobQueue = JobQueue(
            venueRepository: repository,
            venueWebsiteCrawler: crawler,
            venueDealExtractionService: FakeVenueDealExtractor { _, _ in
                VenueDealExtractionResults(dealsFoundBeforeCondensing: 0, dealsFound: 0, duration: 0, errorCount: 0)
            }
        )

        _ = jobQueue.enqueue(venueId: 1, type: .crawlWebsite)
        _ = jobQueue.enqueue(venueId: 2, type: .crawlWebsite)
        let pendingJobID = jobQueue.enqueue(venueId: 3, type: .crawlWebsite)
        #expect(pendingJobID != nil)

        if let pendingJobID {
            jobQueue.cancel(jobId: pendingJobID)
            let pendingJob = jobQueue.jobs.first { $0.id == pendingJobID }
            #expect(pendingJob?.status == .cancelled)
        }

        await waitForJobs(toFinish: 3, in: jobQueue)
    }

    @Test func cancelRunningJobMarksCancelled() async {
        let repository = makeRepository(with: makeVenue())
        let crawler = FakeVenueWebsiteCrawler { _, _ in
            try await Task.sleep(for: .milliseconds(200))
            return VenueCrawlResults(dealsFound: 0, visitedPages: [], imagesAnalyzed: 0, duration: 0)
        }

        let jobQueue = JobQueue(
            venueRepository: repository,
            venueWebsiteCrawler: crawler,
            venueDealExtractionService: FakeVenueDealExtractor { _, _ in
                VenueDealExtractionResults(dealsFoundBeforeCondensing: 0, dealsFound: 0, duration: 0, errorCount: 0)
            }
        )

        let jobID = jobQueue.enqueue(venueId: 1, type: .crawlWebsite)
        await waitUntilRunning(jobId: jobID!, in: jobQueue)
        jobQueue.cancel(jobId: jobID!)
        await waitForJob(toFinish: jobID!, in: jobQueue)

        let job = jobQueue.jobs.first { $0.id == jobID }
        #expect(job?.status == .cancelled)
    }

    @Test func progressUpdatesPropagate() async {
        let venue = makeVenue()
        let repository = makeRepository(with: venue)
        let crawler = FakeVenueWebsiteCrawler { _, progress in
            await progress("Step one")
            await progress("Step two")
            return VenueCrawlResults(dealsFound: 0, visitedPages: [], imagesAnalyzed: 0, duration: 0)
        }

        let jobQueue = JobQueue(
            venueRepository: repository,
            venueWebsiteCrawler: crawler,
            venueDealExtractionService: FakeVenueDealExtractor { _, _ in
                VenueDealExtractionResults(dealsFoundBeforeCondensing: 0, dealsFound: 0, duration: 0, errorCount: 0)
            }
        )

        let jobID = jobQueue.enqueue(venueId: 1, type: .crawlWebsite)
        await waitForJob(toFinish: jobID!, in: jobQueue)

        let job = jobQueue.jobs.first { $0.id == jobID }
        if case let .completed(.crawl(results)) = job?.status {
            #expect(results.dealsFound == 0)
        } else {
            Issue.record("Expected completed crawl job")
        }
    }

    @Test func jobsForVenueFiltersCorrectly() async {
        let venueOne = makeVenue(id: 1)
        let venueTwo = makeVenue(id: 2)
        let repository = makeRepository(with: venueOne)
        try! repository.upsert(venueTwo)

        let jobQueue = JobQueue(
            venueRepository: repository,
            venueWebsiteCrawler: FakeVenueWebsiteCrawler { _, _ in
                VenueCrawlResults(dealsFound: 0, visitedPages: [], imagesAnalyzed: 0, duration: 0)
            },
            venueDealExtractionService: FakeVenueDealExtractor { _, _ in
                VenueDealExtractionResults(dealsFoundBeforeCondensing: 0, dealsFound: 0, duration: 0, errorCount: 0)
            }
        )

        _ = jobQueue.enqueue(venueId: 1, type: .crawlWebsite)
        _ = jobQueue.enqueue(venueId: 2, type: .crawlWebsite)

        await waitForJobs(toFinish: 2, in: jobQueue)

        #expect(jobQueue.jobs(for: 1).count == 1)
        #expect(jobQueue.jobs(for: 2).count == 1)
        #expect(jobQueue.jobs(for: 99).isEmpty)
    }

    private func waitForJobs(toFinish count: Int, in jobQueue: JobQueue) async {
        for _ in 0..<100 {
            let finished = jobQueue.jobs.filter { job in
                switch job.status {
                case .completed, .failed, .cancelled:
                    return true
                case .pending, .running:
                    return false
                }
            }.count
            if finished >= count { return }
            try? await Task.sleep(for: .milliseconds(20))
        }
        Issue.record("Timed out waiting for jobs to finish")
    }

    private func waitForJob(toFinish jobID: UUID, in jobQueue: JobQueue) async {
        for _ in 0..<100 {
            guard let job = jobQueue.jobs.first(where: { $0.id == jobID }) else { return }
            switch job.status {
            case .completed, .failed, .cancelled:
                return
            case .pending, .running:
                try? await Task.sleep(for: .milliseconds(20))
            }
        }
        Issue.record("Timed out waiting for job to finish")
    }

    private func waitUntilRunning(jobId: UUID, in jobQueue: JobQueue) async {
        for _ in 0..<100 {
            guard let job = jobQueue.jobs.first(where: { $0.id == jobId }) else { return }
            if case .running = job.status { return }
            try? await Task.sleep(for: .milliseconds(10))
        }
    }
}

@MainActor
private final class FakeVenueWebsiteCrawler: VenueWebsiteCrawling {
    private let handler: (Venue, ProgressMonitor<VenueCrawlResults>) async throws -> VenueCrawlResults

    init(
        handler: @escaping (Venue, ProgressMonitor<VenueCrawlResults>) async throws -> VenueCrawlResults
    ) {
        self.handler = handler
    }

    func crawl(
        venue: Venue,
        progress: ProgressMonitor<VenueCrawlResults>
    ) async throws -> VenueCrawlResults {
        try await handler(venue, progress)
    }
}

@MainActor
private final class FakeVenueDealExtractor: VenueDealExtracting {
    private let handler: (Venue, ProgressMonitor<VenueDealExtractionResults>) async throws -> VenueDealExtractionResults

    init(
        handler: @escaping (Venue, ProgressMonitor<VenueDealExtractionResults>) async throws -> VenueDealExtractionResults
    ) {
        self.handler = handler
    }

    func extractDeals(
        for venue: Venue,
        progress: ProgressMonitor<VenueDealExtractionResults>
    ) async throws -> VenueDealExtractionResults {
        try await handler(venue, progress)
    }
}
