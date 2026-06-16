//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct DealSourceExtractorTests {

    private let extractor = DealSourceExtractor()

    private func loadedPage(
        html: String,
        url: URL,
        imageURLs: [URL] = []
    ) -> LoadedPage {
        LoadedPage(url: url, html: html, imageURLs: imageURLs, contentBlocks: [], links: [])
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
        let pageURL = URL(string: "https://pub.example.com/happy-hour")!

        let result = try extractor.extract(
            page: loadedPage(html: html, url: pageURL)
        )

        #expect(result.contains {
            $0.type == .image && $0.url.lastPathComponent == "happy-hour-board.png"
        })
    }

    @Test func extractsImageOnDealKeywordPageTitle() throws {
        let html = """
        <html>
        <head><title>Happy Hour</title></head>
        <body>
          <img src="/images/board.png" alt="Today's offers">
        </body>
        </html>
        """
        let pageURL = URL(string: "https://pub.example.com/happy-hour")!

        let result = try extractor.extract(
            page: loadedPage(html: html, url: pageURL)
        )

        #expect(result.contains {
            $0.type == .image && $0.url.lastPathComponent == "board.png"
        })
    }

    @Test func ignoresImageWithoutKeywordOnNonDealPage() throws {
        let html = """
        <html>
        <head><title>Home</title></head>
        <body>
          <img src="/images/logo.png" alt="Company logo">
        </body>
        </html>
        """
        let pageURL = URL(string: "https://pub.example.com/")!

        let result = try extractor.extract(
            page: loadedPage(html: html, url: pageURL)
        )

        #expect(result.isEmpty)
    }
}
