//Created by Alex Skorulis on 22/6/2026.

import Foundation

@MainActor
protocol VenueWebsiteCrawling {
    func crawl(
        venue: Venue,
        progress: ProgressMonitor<VenueCrawlResults>
    ) async throws -> VenueCrawlResults
}

extension VenueWebsiteCrawler: VenueWebsiteCrawling {}

@MainActor
protocol VenueDealExtracting {
    func extractDeals(
        for venue: Venue,
        progress: ProgressMonitor<VenueDealExtractionResults>
    ) async throws -> VenueDealExtractionResults
}

extension VenueDealExtractionService: VenueDealExtracting {}

@MainActor
protocol SuburbCrawling {
    func crawl(
        suburb: Suburb,
        progress: ProgressMonitor<SuburbCrawlResults>
    ) async throws -> SuburbCrawlResults
}

extension SuburbCrawler: SuburbCrawling {}
