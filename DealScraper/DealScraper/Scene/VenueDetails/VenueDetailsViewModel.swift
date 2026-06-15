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
        case completed(found: Int)
        case failed(message: String)
    }

    let googleMapId: String
    private(set) var venue: Venue?
    private(set) var crawlState: CrawlState = .idle

    private let venueRepository: VenueRepository
    private let venueWebsiteCrawler: VenueWebsiteCrawler

    @Resolvable<Resolver>
    init(
        @Argument googleMapId: String,
        venueRepository: VenueRepository,
        venueWebsiteCrawler: VenueWebsiteCrawler
    ) {
        self.googleMapId = googleMapId
        self.venueRepository = venueRepository
        self.venueWebsiteCrawler = venueWebsiteCrawler
        load()
    }

    var canCrawl: Bool {
        venue?.websiteUri != nil && !isCrawling
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

    private func load() {
        venue = try? venueRepository.find(googleMapId: googleMapId)
    }

    private func performCrawl(venue: Venue) async {
        crawlState = .crawling(progress: "Starting crawl…")

        do {
            let newCount = try await venueWebsiteCrawler.crawl(venue: venue) { [weak self] progress in
                Task { @MainActor in
                    switch progress {
                    case let .loadingPage(url):
                        self?.crawlState = .crawling(progress: "Loading \(url.host ?? url.absoluteString)…")
                    case .saving:
                        self?.crawlState = .crawling(progress: "Saving deal sources…")
                    case let .completed(newCount):
                        self?.crawlState = .completed(found: newCount)
                    case let .failed(message):
                        self?.crawlState = .failed(message: message)
                    }
                }
            }

            load()
            crawlState = .completed(found: newCount)
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
