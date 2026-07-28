//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct URLNormalizerTests {

    @Test func normalizeStripsFragmentAndTrailingSlash() throws {
        let base = URL(string: "https://Example.com/menu/")!
        let normalized = try #require(URLNormalizer.normalize(base))

        #expect(normalized.absoluteString == "https://example.com/menu")
    }

    @Test func hashIsStableForEquivalentURLs() throws {
        let urlA = try #require(URLNormalizer.normalize(URL(string: "https://pub.example.com/specials/")!))
        let urlB = try #require(URLNormalizer.normalize(URL(string: "https://pub.example.com/specials#top")!))

        #expect(URLNormalizer.hash(urlA) == URLNormalizer.hash(urlB))
    }

    @Test func resolveRelativeURLAgainstPage() throws {
        let pageURL = URL(string: "https://pub.example.com/whats-on")!
        let resolved = try #require(URLNormalizer.resolve("/menu.pdf", relativeTo: pageURL))

        #expect(resolved.absoluteString == "https://pub.example.com/menu.pdf")
    }

    @Test func normalizePreservesHTTPScheme() throws {
        let httpURL = URL(string: "http://www.mooringsrestaurant.co.nz/")!
        let normalized = try #require(URLNormalizer.normalize(httpURL))

        #expect(normalized.scheme == "http")
        #expect(normalized.absoluteString == "http://www.mooringsrestaurant.co.nz/")
    }

    @Test func hashIsStableForHTTPAndHTTPS() throws {
        let httpURL = try #require(URLNormalizer.normalize(URL(string: "http://pub.example.com/specials")!))
        let httpsURL = try #require(URLNormalizer.normalize(URL(string: "https://pub.example.com/specials")!))

        #expect(httpURL.scheme == "http")
        #expect(httpsURL.scheme == "https")
        #expect(URLNormalizer.hash(httpURL) == URLNormalizer.hash(httpsURL))
    }

    @Test func isSameOriginMatchesHostAndScheme() throws {
        let base = URL(string: "https://pub.example.com")!
        let same = URL(string: "https://pub.example.com/events")!
        let different = URL(string: "https://cdn.example.com/menu.pdf")!

        #expect(URLNormalizer.isSameOrigin(same, as: base))
        #expect(!URLNormalizer.isSameOrigin(different, as: base))

        let httpSameHost = URL(string: "http://pub.example.com/events")!
        #expect(URLNormalizer.isSameOrigin(httpSameHost, as: base))
    }

    @Test func isSameOriginTreatsWWWAsEquivalent() throws {
        let base = URL(string: "https://www.greatsouthernbar.com.au")!
        let withoutWWW = URL(string: "https://greatsouthernbar.com.au/whats-on")!

        #expect(URLNormalizer.isSameOrigin(withoutWWW, as: base))
        #expect(URLNormalizer.isSameOrigin(base, as: withoutWWW))
    }

    @Test func resolveRelativeURLAgainstHTTPPagePreservesHTTP() throws {
        let pageURL = URL(string: "http://pub.example.com/whats-on")!
        let resolved = try #require(URLNormalizer.resolve("/menu.pdf", relativeTo: pageURL))

        #expect(resolved.absoluteString == "http://pub.example.com/menu.pdf")
    }

    @Test func stripGoogleTrackingParametersRemovesGMBQueryString() {
        let tracked = "https://pub.example.com/?utm_source=google&utm_medium=organic&utm_campaign=gmb&utm_term=plcid_8384449097513870665"
        #expect(URLNormalizer.stripGoogleTrackingParameters(from: tracked) == "https://pub.example.com/")
    }

    @Test func stripGoogleTrackingParametersPreservesOtherQueryItems() {
        let url = "https://pub.example.com/menu?section=drinks&utm_source=google&utm_medium=organic"
        #expect(URLNormalizer.stripGoogleTrackingParameters(from: url) == "https://pub.example.com/menu?section=drinks")
    }
}
