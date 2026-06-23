//Created by Alex Skorulis on 23/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct CrawlPolicyTests {

    @Test func merivaleVenuesAreLimitedToFirstPage() throws {
        let venueURL = try #require(URLNormalizer.normalize(URL(string: "https://merivale.com/venues/coogee-pavilion")!))
        #expect(CrawlPolicy.maxPages(for: venueURL) == 1)
    }

    @Test func merivaleWWWVenuesAreLimitedToFirstPage() throws {
        let venueURL = try #require(URLNormalizer.normalize(URL(string: "https://www.merivale.com/venues/coogee-pavilion")!))
        #expect(CrawlPolicy.maxPages(for: venueURL) == 1)
    }

    @Test func otherVenuesUseDefaultPageLimit() throws {
        let venueURL = try #require(URLNormalizer.normalize(URL(string: "https://pub.example.com/specials")!))
        #expect(CrawlPolicy.maxPages(for: venueURL) == 15)
    }

    @Test func merivaleVenuesSkipSitemap() throws {
        let venueURL = try #require(URLNormalizer.normalize(URL(string: "https://merivale.com/venues/coogee-pavilion")!))
        #expect(CrawlPolicy.shouldUseSitemap(for: venueURL) == false)
    }

    @Test func merivaleWWWVenuesSkipSitemap() throws {
        let venueURL = try #require(URLNormalizer.normalize(URL(string: "https://www.merivale.com/venues/coogee-pavilion")!))
        #expect(CrawlPolicy.shouldUseSitemap(for: venueURL) == false)
    }

    @Test func otherVenuesUseSitemap() throws {
        let venueURL = try #require(URLNormalizer.normalize(URL(string: "https://pub.example.com/specials")!))
        #expect(CrawlPolicy.shouldUseSitemap(for: venueURL) == true)
    }
}
