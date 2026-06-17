//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Knit
import KnitMacros

@MainActor
@Observable
final class VenueDetailsViewModel {

    enum CrawlState: Equatable {
        case idle
        case crawling(progress: String)
        case completed(VenueCrawlResults)
        case failed(message: String)
    }

    enum DeleteSourcesState: Equatable {
        case idle
        case completed(deleted: Int)
        case failed(message: String)
    }

    enum ExtractionState: Equatable {
        case idle
        case extracting(progress: String)
        case completed(count: Int)
        case failed(message: String)
    }

    let googleMapId: String
    private(set) var venue: Venue?
    private(set) var venueLinks: VenueLinks?
    private(set) var dealSources: [DealSource] = []
    private(set) var deals: [DealWithSchedules] = []
    private(set) var crawlState: CrawlState = .idle
    private(set) var deleteSourcesState: DeleteSourcesState = .idle
    private(set) var extractionState: ExtractionState = .idle

    var extractionProvider: VenueDealExtractionProvider = .cursor
    var cursorModel: String = "composer-2.5"

    private let venueRepository: VenueRepository
    private let dealSourceRepository: DealSourceRepository
    private let dealRepository: DealRepository
    private let venueLinksRepository: VenueLinksRepository
    private let venueWebsiteCrawler: VenueWebsiteCrawler
    private let venueDealExtractionService: VenueDealExtractionService

    @Resolvable<Resolver>
    init(
        @Argument googleMapId: String,
        venueRepository: VenueRepository,
        dealSourceRepository: DealSourceRepository,
        dealRepository: DealRepository,
        venueLinksRepository: VenueLinksRepository,
        venueWebsiteCrawler: VenueWebsiteCrawler,
        venueDealExtractionService: VenueDealExtractionService
    ) {
        self.googleMapId = googleMapId
        self.venueRepository = venueRepository
        self.dealSourceRepository = dealSourceRepository
        self.dealRepository = dealRepository
        self.venueLinksRepository = venueLinksRepository
        self.venueWebsiteCrawler = venueWebsiteCrawler
        self.venueDealExtractionService = venueDealExtractionService
        load()
    }

    var canCrawl: Bool {
        venue?.websiteUri != nil && !isCrawling
    }

    var canDeleteSources: Bool {
        venue?.id != nil && !isCrawling
    }

    var isCrawling: Bool {
        if case .crawling = crawlState { return true }
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
        crawlState = .crawling(progress: "Starting crawl…")
        deleteSourcesState = .idle

        do {
            let results = try await venueWebsiteCrawler.crawl(venue: venue) { [weak self] progress in
                Task { @MainActor in
                    switch progress {
                    case let .loadingPage(url):
                        self?.crawlState = .crawling(progress: "Loading \(url.absoluteString)…")
                    case let .validatingImage(url):
                        self?.crawlState = .crawling(progress: "Checking image \(url.lastPathComponent)…")
                    case .saving:
                        self?.crawlState = .crawling(progress: "Saving deal sources…")
                    case let .completed(results):
                        self?.crawlState = .completed(results)
                    case let .failed(message):
                        self?.crawlState = .failed(message: message)
                    }
                }
            }

            load()
            crawlState = .completed(results)
        } catch {
            crawlState = .failed(message: error.localizedDescription)
        }
    }

    private func performExtraction(venue: Venue) async {
        extractionState = .extracting(progress: "Preparing sources…")

        do {
            let count = try await venueDealExtractionService.extractDeals(
                for: venue,
                provider: extractionProvider,
                model: cursorModel
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.extractionState = .extracting(progress: progress)
                }
            }

            load()
            extractionState = .completed(count: count)
        } catch {
            extractionState = .failed(message: error.localizedDescription)
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
