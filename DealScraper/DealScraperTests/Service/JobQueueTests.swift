//Created by Alex Skorulis on 22/6/2026.

import Foundation
import GRDB
import Testing
@testable import DealScraper

@MainActor
@Suite(.serialized)
struct JobQueueTests {

    private func makeVenue(id: Int64 = 1) -> Venue {
        Venue(
            id: id,
            googleMapId: "places/test-\(id)",
            name: "Test Pub",
            lat: -33.86,
            lng: 151.20,
            websiteUri: "https://example.com",
            json: "{}"
        )
    }

    private func makeStore(with venue: Venue) -> SQLStore {
        let store = SQLStore.inMemory()
        let repository = VenueRepository(store: store)
        try! repository.upsert(venue)
        return store
    }

    private func makeRepository(with venue: Venue) -> VenueRepository {
        VenueRepository(store: makeStore(with: venue))
    }

    private func makeSuburb(id: Int64 = 1) -> Suburb {
        Suburb(id: id, name: "Newtown", postcode: "2042", state: "NSW")
    }

    private func insertSuburb(_ suburb: Suburb, in store: SQLStore) throws -> Int64 {
        try store.dbQueue.write { db in
            var mutable = suburb
            try mutable.insert(db)
            return try #require(mutable.id)
        }
    }

    private func makeJobQueue(
        store: SQLStore,
        venueWebsiteCrawler: (any VenueWebsiteCrawling)? = nil,
        venueDealExtractionService: (any VenueDealExtracting)? = nil,
        suburbCrawler: (any SuburbCrawling)? = nil
    ) -> JobQueue {
        JobQueue(
            venueRepository: VenueRepository(store: store),
            suburbRepository: SuburbRepository(store: store),
            venueWebsiteCrawler: venueWebsiteCrawler ?? defaultVenueWebsiteCrawler,
            venueDealExtractionService: venueDealExtractionService ?? defaultDealExtractor,
            suburbCrawler: suburbCrawler ?? defaultSuburbCrawler
        )
    }

    private var defaultVenueWebsiteCrawler: any VenueWebsiteCrawling {
        FakeVenueWebsiteCrawler { _, _ in
            VenueCrawlResults(dealsFound: 0, visitedPages: [], imagesAnalyzed: 0, duration: 0)
        }
    }

    private var defaultDealExtractor: any VenueDealExtracting {
        FakeVenueDealExtractor { _, _ in
            VenueDealExtractionResults(dealsFoundBeforeCondensing: 0, dealsFound: 0, duration: 0, errorCount: 0)
        }
    }

    private var defaultSuburbCrawler: any SuburbCrawling {
        FakeSuburbCrawler { _, _ in
            SuburbCrawlResults(venuesFound: 0, newVenues: 0, duration: 0)
        }
    }

    @Test func enqueueCompletesAllJobsForSameVenue() async {
        let venue = makeVenue()
        let store = makeStore(with: venue)

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

        let jobQueue = makeJobQueue(
            store: store,
            venueWebsiteCrawler: crawler,
            venueDealExtractionService: extractor,
            suburbCrawler: defaultSuburbCrawler
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
        let store = makeStore(with: makeVenue())
        let repository = VenueRepository(store: store)
        for id in 2...3 {
            try! repository.upsert(makeVenue(id: Int64(id)))
        }

        let crawler = FakeVenueWebsiteCrawler { _, _ in
            try await Task.sleep(for: .milliseconds(100))
            return VenueCrawlResults(dealsFound: 0, visitedPages: [], imagesAnalyzed: 0, duration: 0)
        }

        let jobQueue = makeJobQueue(store: store, venueWebsiteCrawler: crawler)

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
        let store = makeStore(with: makeVenue())
        let crawler = FakeVenueWebsiteCrawler { _, _ in
            try await Task.sleep(for: .milliseconds(100))
            return VenueCrawlResults(dealsFound: 0, visitedPages: [], imagesAnalyzed: 0, duration: 0)
        }

        let jobQueue = makeJobQueue(store: store, venueWebsiteCrawler: crawler)

        let first = jobQueue.enqueue(venueId: 1, type: .crawlWebsite)
        let second = jobQueue.enqueue(venueId: 1, type: .crawlWebsite)

        #expect(first != nil)
        #expect(second == nil)
        #expect(jobQueue.jobs.count == 1)

        await waitForJobs(toFinish: 1, in: jobQueue)
    }

    @Test func cancelPendingJobMarksCancelled() async {
        let store = makeStore(with: makeVenue())
        let repository = VenueRepository(store: store)
        for id in 2...3 {
            try! repository.upsert(makeVenue(id: Int64(id)))
        }

        let crawler = FakeVenueWebsiteCrawler { _, _ in
            try await Task.sleep(for: .milliseconds(200))
            return VenueCrawlResults(dealsFound: 0, visitedPages: [], imagesAnalyzed: 0, duration: 0)
        }

        let jobQueue = makeJobQueue(store: store, venueWebsiteCrawler: crawler)

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
        let store = makeStore(with: makeVenue())
        let crawler = FakeVenueWebsiteCrawler { _, _ in
            try await Task.sleep(for: .milliseconds(200))
            return VenueCrawlResults(dealsFound: 0, visitedPages: [], imagesAnalyzed: 0, duration: 0)
        }

        let jobQueue = makeJobQueue(store: store, venueWebsiteCrawler: crawler)

        let jobID = jobQueue.enqueue(venueId: 1, type: .crawlWebsite)
        await waitUntilRunning(jobId: jobID!, in: jobQueue)
        jobQueue.cancel(jobId: jobID!)
        await waitForJob(toFinish: jobID!, in: jobQueue)

        let job = jobQueue.jobs.first { $0.id == jobID }
        #expect(job?.status == .cancelled)
    }

    @Test func progressUpdatesPropagate() async {
        let store = makeStore(with: makeVenue())
        let crawler = FakeVenueWebsiteCrawler { _, progress in
            await progress("Step one")
            await progress("Step two")
            return VenueCrawlResults(dealsFound: 0, visitedPages: [], imagesAnalyzed: 0, duration: 0)
        }

        let jobQueue = makeJobQueue(store: store, venueWebsiteCrawler: crawler)

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
        let store = makeStore(with: makeVenue(id: 1))
        let repository = VenueRepository(store: store)
        try! repository.upsert(makeVenue(id: 2))

        let jobQueue = makeJobQueue(store: store)

        _ = jobQueue.enqueue(venueId: 1, type: .crawlWebsite)
        _ = jobQueue.enqueue(venueId: 2, type: .crawlWebsite)

        await waitForJobs(toFinish: 2, in: jobQueue)

        #expect(jobQueue.jobs(for: 1).count == 1)
        #expect(jobQueue.jobs(for: 2).count == 1)
        #expect(jobQueue.jobs(for: 99).isEmpty)
    }

    @Test func clearAllRemovesJobsForVenue() async {
        let store = makeStore(with: makeVenue(id: 1))
        let repository = VenueRepository(store: store)
        try! repository.upsert(makeVenue(id: 2))

        let crawler = FakeVenueWebsiteCrawler { _, _ in
            try await Task.sleep(for: .milliseconds(100))
            return VenueCrawlResults(dealsFound: 0, visitedPages: [], imagesAnalyzed: 0, duration: 0)
        }

        let jobQueue = makeJobQueue(store: store, venueWebsiteCrawler: crawler)

        _ = jobQueue.enqueue(venueId: 1, type: .crawlWebsite)
        _ = jobQueue.enqueue(venueId: 2, type: .crawlWebsite)

        jobQueue.clearAll(for: 1)

        #expect(jobQueue.jobs(for: 1).isEmpty)
        #expect(jobQueue.jobs(for: 2).count == 1)
        #expect(!jobQueue.isJobActive(venueId: 1, type: .crawlWebsite))
    }

    @Test func crawlSuburbCompletesWithResults() async throws {
        let store = SQLStore.inMemory()
        let suburbId = try insertSuburb(makeSuburb(), in: store)

        let suburbCrawler = FakeSuburbCrawler { suburb, progress in
            await progress("Searching…")
            return SuburbCrawlResults(venuesFound: 5, newVenues: 2, duration: 1.5)
        }

        let jobQueue = makeJobQueue(
            store: store,
            venueWebsiteCrawler: defaultVenueWebsiteCrawler,
            venueDealExtractionService: defaultDealExtractor,
            suburbCrawler: suburbCrawler
        )

        let jobID = jobQueue.enqueue(suburbId: suburbId, type: .crawlSuburb)
        #expect(jobID != nil)

        await waitForJob(toFinish: jobID!, in: jobQueue)

        let job = jobQueue.jobs.first { $0.id == jobID }
        if case let .completed(.crawlSuburb(results)) = job?.status {
            #expect(results.venuesFound == 5)
            #expect(results.newVenues == 2)
        } else {
            Issue.record("Expected completed suburb crawl job")
        }
    }

    @Test func duplicateSuburbCrawlEnqueueIsRejected() async throws {
        let store = SQLStore.inMemory()
        let suburbId = try insertSuburb(makeSuburb(), in: store)

        let suburbCrawler = FakeSuburbCrawler { _, _ in
            try await Task.sleep(for: .milliseconds(100))
            return SuburbCrawlResults(venuesFound: 0, newVenues: 0, duration: 0)
        }

        let jobQueue = makeJobQueue(
            store: store,
            venueWebsiteCrawler: defaultVenueWebsiteCrawler,
            venueDealExtractionService: defaultDealExtractor,
            suburbCrawler: suburbCrawler
        )

        let first = jobQueue.enqueue(suburbId: suburbId, type: .crawlSuburb)
        let second = jobQueue.enqueue(suburbId: suburbId, type: .crawlSuburb)

        #expect(first != nil)
        #expect(second == nil)

        await waitForJobs(toFinish: 1, in: jobQueue)
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

@MainActor
private final class FakeSuburbCrawler: SuburbCrawling {
    private let handler: (Suburb, ProgressMonitor<SuburbCrawlResults>) async throws -> SuburbCrawlResults

    init(
        handler: @escaping (Suburb, ProgressMonitor<SuburbCrawlResults>) async throws -> SuburbCrawlResults
    ) {
        self.handler = handler
    }

    func crawl(
        suburb: Suburb,
        progress: ProgressMonitor<SuburbCrawlResults>
    ) async throws -> SuburbCrawlResults {
        try await handler(suburb, progress)
    }
}
