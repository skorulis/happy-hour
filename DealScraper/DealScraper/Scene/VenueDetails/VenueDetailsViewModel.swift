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

    let googleMapId: String
    private(set) var venue: Venue?
    private(set) var venueLinks: VenueLinks?
    private(set) var dealSources: [DealSource] = []
    private(set) var crawlState: CrawlState = .idle
    private(set) var deleteSourcesState: DeleteSourcesState = .idle

    private let venueRepository: VenueRepository
    private let dealSourceRepository: DealSourceRepository
    private let venueLinksRepository: VenueLinksRepository
    private let venueWebsiteCrawler: VenueWebsiteCrawler

    @Resolvable<Resolver>
    init(
        @Argument googleMapId: String,
        venueRepository: VenueRepository,
        dealSourceRepository: DealSourceRepository,
        venueLinksRepository: VenueLinksRepository,
        venueWebsiteCrawler: VenueWebsiteCrawler
    ) {
        self.googleMapId = googleMapId
        self.venueRepository = venueRepository
        self.dealSourceRepository = dealSourceRepository
        self.venueLinksRepository = venueLinksRepository
        self.venueWebsiteCrawler = venueWebsiteCrawler
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

    private func load() {
        venue = try? venueRepository.find(googleMapId: googleMapId)
        if let venueId = venue?.id {
            venueLinks = try? venueLinksRepository.find(venueId: venueId)
            dealSources = (try? dealSourceRepository.find(venueId: venueId)) ?? []
        } else {
            venueLinks = nil
            dealSources = []
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
