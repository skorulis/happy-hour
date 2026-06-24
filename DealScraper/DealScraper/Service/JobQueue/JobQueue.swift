//Created by Alex Skorulis on 22/6/2026.

import Foundation
import Knit
import KnitMacros

@MainActor
@Observable
final class JobQueue {

    private(set) var jobs: [JobItem] = []

    private let venueRepository: VenueRepository
    private let venueWebsiteCrawler: any VenueWebsiteCrawling
    private let venueDealExtractionService: any VenueDealExtracting

    private let maxConcurrentJobs = 2

    private var runningTasks: [UUID: Task<Void, Never>] = [:]
    private var completionHandlers: [UUID: @MainActor () -> Void] = [:]

    @Resolvable<Resolver>
    init(
        venueRepository: VenueRepository,
        venueWebsiteCrawler: VenueWebsiteCrawler,
        venueDealExtractionService: VenueDealExtractionService
    ) {
        self.venueRepository = venueRepository
        self.venueWebsiteCrawler = venueWebsiteCrawler
        self.venueDealExtractionService = venueDealExtractionService
    }

    init(
        venueRepository: VenueRepository,
        venueWebsiteCrawler: any VenueWebsiteCrawling,
        venueDealExtractionService: any VenueDealExtracting
    ) {
        self.venueRepository = venueRepository
        self.venueWebsiteCrawler = venueWebsiteCrawler
        self.venueDealExtractionService = venueDealExtractionService
    }

    @discardableResult
    func enqueue(
        venueId: Int64,
        type: JobType,
        onComplete: (@MainActor () -> Void)? = nil
    ) -> UUID? {
        guard !isJobActive(venueId: venueId, type: type) else { return nil }

        let job = JobItem(venueId: venueId, type: type)
        jobs.append(job)
        if let onComplete {
            completionHandlers[job.id] = onComplete
        }
        pumpQueue()
        return job.id
    }

    func cancel(jobId: UUID) {
        guard let index = jobs.firstIndex(where: { $0.id == jobId }) else { return }

        switch jobs[index].status {
        case .pending:
            jobs[index].status = .cancelled
            completionHandlers.removeValue(forKey: jobId)
        case .running:
            runningTasks[jobId]?.cancel()
        case .completed, .failed, .cancelled:
            break
        }
    }

    func jobs(for venueId: Int64) -> [JobItem] {
        jobs.filter { $0.venueId == venueId }
    }

    func latestJob(venueId: Int64, type: JobType) -> JobItem? {
        jobs.last { $0.venueId == venueId && $0.type == type }
    }

    func isJobActive(venueId: Int64, type: JobType) -> Bool {
        jobs.contains { job in
            job.venueId == venueId && job.type == type && job.status.isActive
        }
    }

    func clearCompleted(for venueId: Int64, type: JobType) {
        jobs.removeAll { job in
            guard job.venueId == venueId, job.type == type else { return false }
            if case .completed = job.status { return true }
            return false
        }
    }

    private func pumpQueue() {
        while runningTasks.count < maxConcurrentJobs,
              let nextIndex = jobs.firstIndex(where: { job in
                  if case .pending = job.status { return true }
                  return false
              })
        {
            let jobId = jobs[nextIndex].id
            updateJobStatus(jobId: jobId, status: .running(progress: "Starting…"))

            let executionTask = Task {
                await executeJob(jobId: jobId)
                jobDidFinish(jobId: jobId)
            }
            runningTasks[jobId] = executionTask
        }
    }

    private func jobDidFinish(jobId: UUID) {
        runningTasks.removeValue(forKey: jobId)
        pumpQueue()
    }

    private func executeJob(jobId: UUID) async {
        guard let job = jobs.first(where: { $0.id == jobId }) else { return }

        do {
            try Task.checkCancellation()

            guard let venue = try venueRepository.find(id: job.venueId) else {
                updateJobStatus(jobId: jobId, status: .failed(message: "Venue not found."))
                completionHandlers.removeValue(forKey: jobId)
                return
            }

            switch job.type {
            case .crawlWebsite:
                let results = try await runCrawl(venue: venue, jobId: jobId)
                updateJobStatus(jobId: jobId, status: .completed(.crawl(results)))
            case .extractDeals:
                let results = try await runExtraction(venue: venue, jobId: jobId)
                updateJobStatus(jobId: jobId, status: .completed(.extract(results)))
            }

            invokeCompletion(for: jobId)
        } catch is CancellationError {
            updateJobStatus(jobId: jobId, status: .cancelled)
            completionHandlers.removeValue(forKey: jobId)
        } catch {
            if Task.isCancelled {
                updateJobStatus(jobId: jobId, status: .cancelled)
            } else {
                updateJobStatus(jobId: jobId, status: .failed(message: error.localizedDescription))
            }
            completionHandlers.removeValue(forKey: jobId)
        }
    }

    private func runCrawl(venue: Venue, jobId: UUID) async throws -> VenueCrawlResults {
        let progress = ProgressMonitor<VenueCrawlResults> { [weak self] newValue in
            guard let self else { return }
            if case let .inProgress(progressText) = newValue {
                updateJobStatus(jobId: jobId, status: .running(progress: progressText))
            }
        }
        return try await venueWebsiteCrawler.crawl(venue: venue, progress: progress)
    }

    private func runExtraction(venue: Venue, jobId: UUID) async throws -> VenueDealExtractionResults {
        let progress = ProgressMonitor<VenueDealExtractionResults> { [weak self] newValue in
            guard let self else { return }
            if case let .inProgress(progressText) = newValue {
                updateJobStatus(jobId: jobId, status: .running(progress: progressText))
            }
        }
        return try await venueDealExtractionService.extractDeals(for: venue, progress: progress)
    }

    private func updateJobStatus(jobId: UUID, status: JobStatus) {
        guard let index = jobs.firstIndex(where: { $0.id == jobId }) else { return }
        if case .running = status, jobs[index].startDate == nil {
            jobs[index].startDate = Date()
        }
        jobs[index].status = status
    }

    private func invokeCompletion(for jobId: UUID) {
        guard let handler = completionHandlers.removeValue(forKey: jobId) else { return }
        handler()
    }
}
