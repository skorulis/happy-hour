//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct DealSourceExtractorTests {

    private let extractor = DealSourceExtractor()

    @Test func extractsPDFMenuLink() throws {
        let html = """
        <html>
        <body>
          <a href="/files/happy-hour-menu.pdf">Happy Hour Menu</a>
        </body>
        </html>
        """
        let baseURL = URL(string: "https://pub.example.com")!
        let pageURL = URL(string: "https://pub.example.com/")!

        let result = try extractor.extract(html: html, pageURL: pageURL, baseURL: baseURL)

        #expect(result.sources.count == 1)
        #expect(result.sources[0].type == .pdf)
        #expect(result.sources[0].url.absoluteString == "https://pub.example.com/files/happy-hour-menu.pdf")
    }

    @Test func extractsWhatsOnPageAndCrawlLink() throws {
        let html = """
        <html>
        <head><title>What's On</title></head>
        <body>
          <a href="/specials">Weekly Specials</a>
        </body>
        </html>
        """
        let baseURL = URL(string: "https://pub.example.com")!
        let pageURL = URL(string: "https://pub.example.com/whats-on")!

        let result = try extractor.extract(html: html, pageURL: pageURL, baseURL: baseURL)

        let types = Set(result.sources.map(\.type))
        #expect(types.contains(.webpage))
        #expect(result.crawlLinks.contains(URL(string: "https://pub.example.com/specials")!))
    }

    @Test func extractsDealImageOnKeywordPage() throws {
        let html = """
        <html>
        <head><title>Happy Hour</title></head>
        <body>
          <img src="/images/happy-hour-board.png" alt="Happy hour deals board">
        </body>
        </html>
        """
        let baseURL = URL(string: "https://pub.example.com")!
        let pageURL = URL(string: "https://pub.example.com/happy-hour")!

        let result = try extractor.extract(html: html, pageURL: pageURL, baseURL: baseURL)

        #expect(result.sources.contains {
            $0.type == .image && $0.url.lastPathComponent == "happy-hour-board.png"
        })
    }

    @Test func ignoresExternalCrawlLinks() throws {
        let html = """
        <html><body>
          <a href="https://other.example.com/specials">Specials</a>
        </body></html>
        """
        let baseURL = URL(string: "https://pub.example.com")!
        let pageURL = URL(string: "https://pub.example.com/")!

        let result = try extractor.extract(html: html, pageURL: pageURL, baseURL: baseURL)

        #expect(result.crawlLinks.isEmpty)
    }
}
