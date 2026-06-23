//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Knit
import KnitMacros

@MainActor
@Observable
final class VenueDetailsViewModel {

    enum DeleteSourcesState: Equatable {
        case idle
        case completed(deleted: Int)
        case failed(message: String)
    }

    enum DeleteDealsState: Equatable {
        case idle
        case completed(deleted: Int)
        case failed(message: String)
    }

    enum ExtractionState: Equatable {
        case idle
        case extracting(progress: String)
        case completed(VenueDealExtractionResults)
        case failed(message: String)
    }

    let googleMapId: String
    private(set) var venue: Venue?
    private(set) var venueLinks: VenueLinks?
    private(set) var dealSources: [DealSource] = []
    private(set) var deals: [DealWithSchedules] = []
    private(set) var deleteSourcesState: DeleteSourcesState = .idle
    private(set) var deleteDealsState: DeleteDealsState = .idle

    var openRouterModel: String = LLMModelStore.defaultOpenRouterModel {
        didSet { llmModelStore.openRouterModel = openRouterModel }
    }

    private let venueRepository: VenueRepository
    private let dealSourceRepository: DealSourceRepository
    private let dealRepository: DealRepository
    private let venueLinksRepository: VenueLinksRepository
    private let jobQueue: JobQueue
    private let llmModelStore: LLMModelStore

    @Resolvable<Resolver>
    init(
        @Argument googleMapId: String,
        venueRepository: VenueRepository,
        dealSourceRepository: DealSourceRepository,
        dealRepository: DealRepository,
        venueLinksRepository: VenueLinksRepository,
        jobQueue: JobQueue,
        llmModelStore: LLMModelStore
    ) {
        self.googleMapId = googleMapId
        self.venueRepository = venueRepository
        self.dealSourceRepository = dealSourceRepository
        self.dealRepository = dealRepository
        self.venueLinksRepository = venueLinksRepository
        self.jobQueue = jobQueue
        self.llmModelStore = llmModelStore
        openRouterModel = llmModelStore.openRouterModel
        load()
    }

    var crawlState: ProgressState<VenueCrawlResults> {
        guard let venueId = venue?.id else { return .idle }
        guard let job = jobQueue.latestJob(venueId: venueId, type: .crawlWebsite) else { return .idle }
        return mapCrawlState(job.status)
    }

    var extractionState: ExtractionState {
        guard let venueId = venue?.id else { return .idle }
        guard let job = jobQueue.latestJob(venueId: venueId, type: .extractDeals) else { return .idle }
        return mapExtractionState(job.status)
    }

    var venueJobs: [JobItem] {
        guard let venueId = venue?.id else { return [] }
        return jobQueue.jobs(for: venueId)
    }

    var canCrawl: Bool {
        venue?.websiteUri != nil && !isCrawling
    }

    var canDeleteSources: Bool {
        venue?.id != nil && !isCrawling
    }

    var isCrawling: Bool {
        guard let venueId = venue?.id else { return false }
        return jobQueue.isJobActive(venueId: venueId, type: .crawlWebsite)
    }

    var isExtracting: Bool {
        guard let venueId = venue?.id else { return false }
        return jobQueue.isJobActive(venueId: venueId, type: .extractDeals)
    }

    var approvedSourceCount: Int {
        dealSources.filter { $0.status == .approved }.count
    }

    var canExtractDeals: Bool {
        venue?.id != nil && approvedSourceCount > 0 && !isExtracting && !isCrawling
    }

    var canDeleteDeals: Bool {
        venue?.id != nil && !isExtracting && !isCrawling
    }

    func crawlWebsite() {
        guard let venueId = venue?.id, canCrawl else { return }

        jobQueue.enqueue(venueId: venueId, type: .crawlWebsite) { [weak self] in
            self?.load()
        }
    }

    func deleteSources() {
        guard let venueId = venue?.id, canDeleteSources else { return }

        do {
            let deleted = try dealSourceRepository.deleteAll(venueId: venueId)
            deleteSourcesState = .completed(deleted: deleted)
            jobQueue.clearCompleted(for: venueId, type: .crawlWebsite)
            load()
        } catch {
            deleteSourcesState = .failed(message: error.localizedDescription)
        }
    }

    func extractDeals() {
        guard let venueId = venue?.id, canExtractDeals else { return }

        jobQueue.enqueue(venueId: venueId, type: .extractDeals) { [weak self] in
            self?.load()
        }
    }

    func deleteDeals() {
        guard let venueId = venue?.id, canDeleteDeals else { return }

        do {
            let deleted = try dealRepository.deleteAll(venueId: venueId)
            deleteDealsState = .completed(deleted: deleted)
            jobQueue.clearCompleted(for: venueId, type: .extractDeals)
            load()
        } catch {
            deleteDealsState = .failed(message: error.localizedDescription)
        }
    }

    func setDealSourceStatus(_ source: DealSource, status: DealStatus) {
        guard let id = source.id else { return }

        do {
            try dealSourceRepository.updateStatus(id: id, status: status)
            if let index = dealSources.firstIndex(where: { $0.id == id }) {
                dealSources[index].status = status
            }
        } catch {
            // Keep the current UI state if persistence fails.
        }
    }

    func setDealStatus(_ item: DealWithSchedules, status: DealStatus) {
        guard let id = item.deal.id else { return }

        do {
            try dealRepository.updateStatus(id: id, status: status)
            if let index = deals.firstIndex(where: { $0.deal.id == id }) {
                deals[index].deal.status = status
            }
        } catch {
            // Keep the current UI state if persistence fails.
        }
    }

    func setVenueStatus(_ status: VenueStatus) {
        guard let venueId = venue?.id else { return }

        do {
            try venueRepository.updateStatus(venueId: venueId, status: status)
            venue?.status = status
        } catch {
            // Keep the current UI state if persistence fails.
        }
    }

    private func load() {
        venue = try? venueRepository.find(googleMapId: googleMapId)
        if let venueId = venue?.id {
            venueLinks = try? venueLinksRepository.find(venueId: venueId)
            dealSources = (try? dealSourceRepository.find(venueId: venueId)) ?? []
            deals = (try? dealRepository.find(venueId: venueId)) ?? []
        } else {
            venueLinks = nil
            dealSources = []
            deals = []
        }
    }

    private func mapCrawlState(_ status: JobStatus) -> ProgressState<VenueCrawlResults> {
        switch status {
        case .pending:
            return .inProgress(progress: "Queued…")
        case let .running(progress):
            return .inProgress(progress: progress)
        case let .completed(.crawl(results)):
            return .completed(results)
        case let .failed(message):
            return .failed(message: message)
        case .cancelled:
            return .idle
        case .completed:
            return .idle
        }
    }

    private func mapExtractionState(_ status: JobStatus) -> ExtractionState {
        switch status {
        case .pending:
            return .extracting(progress: "Queued…")
        case let .running(progress):
            return .extracting(progress: progress)
        case let .completed(.extract(results)):
            return .completed(results)
        case let .failed(message):
            return .failed(message: message)
        case .cancelled:
            return .idle
        case .completed:
            return .idle
        }
    }

    var googlePlace: GooglePlace? {
        guard let venue, let data = venue.json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(GooglePlace.self, from: data)
    }

    var formattedAddress: String? {
        googlePlace?.formattedAddress
    }

    var types: [String] {
        googlePlace?.types ?? []
    }

    var coordinateDescription: String? {
        guard let venue else { return nil }
        return String(format: "%.6f, %.6f", venue.lat, venue.lng)
    }

    var lastCrawlDescription: String {
        guard let lastCrawl = venue?.lastCrawlDate else { return "Never" }
        return lastCrawl.formatted(date: .abbreviated, time: .shortened)
    }

    var lastExtractionDescription: String {
        guard let lastExtraction = venue?.lastExtractionDate else { return "Never" }
        return lastExtraction.formatted(date: .abbreviated, time: .shortened)
    }

    var mapsURL: URL? {
        guard let venue else { return nil }
        return URL(string: "https://www.google.com/maps/search/?api=1&query=\(venue.lat),\(venue.lng)&query_place_id=\(venue.googleMapId)")
    }
}
