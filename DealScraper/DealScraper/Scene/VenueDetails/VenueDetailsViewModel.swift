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
    private(set) var crawlState: ProgressState<VenueCrawlResults> = .idle
    private(set) var deleteSourcesState: DeleteSourcesState = .idle
    private(set) var deleteDealsState: DeleteDealsState = .idle
    private(set) var extractionState: ExtractionState = .idle

    var extractionProvider: VenueDealExtractionProvider = .openAI
    var openAIModel: String = LLMModelStore.defaultOpenAIModel {
        didSet { llmModelStore.openAIModel = openAIModel }
    }
    var openRouterModel: String = LLMModelStore.defaultOpenRouterModel {
        didSet { llmModelStore.openRouterModel = openRouterModel }
    }

    private let venueRepository: VenueRepository
    private let dealSourceRepository: DealSourceRepository
    private let dealRepository: DealRepository
    private let venueLinksRepository: VenueLinksRepository
    private let venueWebsiteCrawler: VenueWebsiteCrawler
    private let venueDealExtractionService: VenueDealExtractionService
    private let llmModelStore: LLMModelStore

    @Resolvable<Resolver>
    init(
        @Argument googleMapId: String,
        venueRepository: VenueRepository,
        dealSourceRepository: DealSourceRepository,
        dealRepository: DealRepository,
        venueLinksRepository: VenueLinksRepository,
        venueWebsiteCrawler: VenueWebsiteCrawler,
        venueDealExtractionService: VenueDealExtractionService,
        llmModelStore: LLMModelStore
    ) {
        self.googleMapId = googleMapId
        self.venueRepository = venueRepository
        self.dealSourceRepository = dealSourceRepository
        self.dealRepository = dealRepository
        self.venueLinksRepository = venueLinksRepository
        self.venueWebsiteCrawler = venueWebsiteCrawler
        self.venueDealExtractionService = venueDealExtractionService
        self.llmModelStore = llmModelStore
        openAIModel = llmModelStore.openAIModel
        openRouterModel = llmModelStore.openRouterModel
        load()
    }

    private var extractionModel: String {
        switch extractionProvider {
        case .openAI:
            openAIModel
        case .openRouter:
            openRouterModel
        }
    }

    var canCrawl: Bool {
        venue?.websiteUri != nil && !isCrawling
    }

    var canDeleteSources: Bool {
        venue?.id != nil && !isCrawling
    }

    var isCrawling: Bool {
        if case .inProgress = crawlState { return true }
        return false
    }

    var isExtracting: Bool {
        if case .extracting = extractionState { return true }
        return false
    }

    var approvedSourceCount: Int {
        dealSources.filter { $0.status == .approved && $0.type != .pdf }.count
    }

    var canExtractDeals: Bool {
        venue?.id != nil && approvedSourceCount > 0 && !isExtracting && !isCrawling
    }

    var canDeleteDeals: Bool {
        venue?.id != nil && !isExtracting && !isCrawling
    }

    func crawlWebsite() {
        guard let venue, canCrawl else { return }

        Task {
            await performCrawl(venue: venue)
        }
    }

    func deleteSources() {
        guard let venueId = venue?.id, canDeleteSources else { return }

        do {
            let deleted = try dealSourceRepository.deleteAll(venueId: venueId)
            deleteSourcesState = .completed(deleted: deleted)
            crawlState = .idle
            load()
        } catch {
            deleteSourcesState = .failed(message: error.localizedDescription)
        }
    }

    func extractDeals() {
        guard let venue, canExtractDeals else { return }

        Task {
            await performExtraction(venue: venue)
        }
    }

    func deleteDeals() {
        guard let venueId = venue?.id, canDeleteDeals else { return }

        do {
            let deleted = try dealRepository.deleteAll(venueId: venueId)
            deleteDealsState = .completed(deleted: deleted)
            extractionState = .idle
            load()
        } catch {
            deleteDealsState = .failed(message: error.localizedDescription)
        }
    }

    func setDealSourceStatus(_ source: DealSource, status: DealSourceStatus) {
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

    private func performCrawl(venue: Venue) async {
        crawlState = .inProgress(progress: "Starting crawl…")
        deleteSourcesState = .idle

        do {
            let crawlProgress = ProgressMonitor { newValue in
                self.crawlState = newValue
            }
            
            let results = try await venueWebsiteCrawler.crawl(venue: venue, progress: crawlProgress)

            load()
            crawlState = .completed(results)
        } catch {
            crawlState = .failed(message: error.localizedDescription)
        }
    }
    
    private func updateState(_ state: ExtractionState) {
        Task { @MainActor in
            self.extractionState = state
        }
    }

    private func performExtraction(venue: Venue) async {
        updateState(.extracting(progress: "Preparing sources…"))

        do {
            let extractionProgress = ProgressMonitor<VenueDealExtractionResults> { newValue in
                if case let .inProgress(progress) = newValue {
                    self.extractionState = .extracting(progress: progress)
                }
            }

            let results = try await venueDealExtractionService.extractDeals(
                for: venue,
                provider: extractionProvider,
                model: extractionModel,
                progress: extractionProgress
            )

            load()
            updateState(.completed(results))
        } catch {
            updateState(.failed(message: error.localizedDescription))
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

    var lastCrawlDescription: String? {
        guard let venue, let lastCrawlDate = venue.lastCrawlDate else { return nil }
        return lastCrawlDate.formatted(date: .abbreviated, time: .shortened)
    }

    var mapsURL: URL? {
        guard let venue else { return nil }
        return URL(string: "https://www.google.com/maps/search/?api=1&query=\(venue.lat),\(venue.lng)&query_place_id=\(venue.googleMapId)")
    }
}
