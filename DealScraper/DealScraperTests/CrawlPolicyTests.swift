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
        #expect(CrawlPolicy.maxPages(for: venueURL) == 20)
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

    @Test func singleDiscoveredSourceIsAutoApproved() {
        #expect(CrawlPolicy.dealSourceStatus(discoveredCount: 1) == .approved)
    }

    @Test func multipleDiscoveredSourcesStayNew() {
        #expect(CrawlPolicy.dealSourceStatus(discoveredCount: 0) == .new)
        #expect(CrawlPolicy.dealSourceStatus(discoveredCount: 2) == .new)
    }

    @Test func rejectsNthWeekdayOfMonthImage() {
        let source = DiscoveredSource(
            url: URL(string: "https://example.com/poster.jpg")!,
            sourceURL: URL(string: "https://example.com/specials")!,
            type: .image,
            textPieces: .textLines(["Steak Night", "First Tuesday of each Month", "$22 steaks"])
        )

        #expect(CrawlPolicy.dealSourceStatus(for: source, discoveredCount: 1) == .rejected)
    }

    @Test func rejectsSingleDateImage() {
        let source = DiscoveredSource(
            url: URL(string: "https://mumbojumbos.com.au/wp-content/uploads/2025/11/TNT_DEC16_FB-1-2048x866.jpg")!,
            sourceURL: URL(string: "https://mumbojumbos.com.au/")!,
            type: .image,
            textPieces: .textLines([
                "PIXAR",
                "TUES DEC I6TH",
                "$3.50 TACOS FROM 5PM",
            ])
        )

        #expect(CrawlPolicy.dealSourceStatus(for: source, discoveredCount: 1) == .rejected)
    }

    @Test func doesNotRejectNormalImage() {
        let source = DiscoveredSource(
            url: URL(string: "https://example.com/poster.jpg")!,
            sourceURL: URL(string: "https://example.com/specials")!,
            type: .image,
            textPieces: .textLines(["Happy Hour", "Every Tuesday 4PM - 6PM", "$8 wines"])
        )

        #expect(CrawlPolicy.dealSourceStatus(for: source, discoveredCount: 1) == .approved)
    }

    @Test func doesNotRejectNthWeekdayTextOnWebpage() {
        let source = DiscoveredSource(
            url: URL(string: "https://example.com/specials")!,
            sourceURL: URL(string: "https://example.com/specials")!,
            type: .webpage,
            textPieces: .textLines(["First Tuesday of each Month"])
        )

        #expect(CrawlPolicy.dealSourceStatus(for: source, discoveredCount: 1) == .approved)
    }
}
