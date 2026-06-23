//Created by Alex Skorulis on 17/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct PageLinkFilterTests {

    private let filter = PageLinkFilter()

    private func link(text: String?, url: String) -> ContentBlockLink {
        ContentBlockLink(text: text, url: URL(string: url)!)
    }

    @Test func includesPDFWithoutKeyword() {
        let result = filter.filter(links: [
            link(text: "Download", url: "https://pub.example.com/files/menu.pdf"),
        ])

        #expect(result.pdfURLs.count == 1)
        #expect(result.pdfURLs[0].absoluteString == "https://pub.example.com/files/menu.pdf")
        #expect(result.crawlURLs.isEmpty)
    }

    @Test func includesKeywordLinkInCrawlURLs() {
        let result = filter.filter(links: [
            link(text: "Weekly Specials", url: "https://pub.example.com/specials"),
        ])

        #expect(result.pdfURLs.isEmpty)
        #expect(result.crawlURLs.count == 1)
        #expect(result.crawlURLs[0].absoluteString == "https://pub.example.com/specials")
    }

    @Test func includesDayInPathInCrawlURLs() {
        let result = filter.filter(links: [
            link(text: nil, url: "https://pub.example.com/tuesday-specials"),
        ])

        #expect(result.pdfURLs.isEmpty)
        #expect(result.crawlURLs.count == 1)
        #expect(result.crawlURLs[0].path == "/tuesday-specials")
    }

    @Test func includesDayInTextInCrawlURLs() {
        let result = filter.filter(links: [
            link(text: "Friday Happy Hour", url: "https://pub.example.com/offers"),
        ])

        #expect(result.pdfURLs.isEmpty)
        #expect(result.crawlURLs.count == 1)
    }
    
    @Test func excludesLinksWithInvalidWords() {
        let result = filter.filter(links: [
            link(text: "Grand Final", url: "https://royalalberthotel.com.au/whatson/nrl-grand-final"),
        ])

        #expect(result.crawlURLs.count == 0)
    }

    @Test func excludesNonMatchingLink() {
        let result = filter.filter(links: [
            link(text: "About Us", url: "https://pub.example.com/about"),
        ])

        #expect(result.pdfURLs.isEmpty)
        #expect(result.crawlURLs.isEmpty)
    }

    @Test func excludesImageLinkWithKeywordFromCrawlURLs() {
        let result = filter.filter(links: [
            link(text: "Happy Hour Board", url: "https://pub.example.com/images/happy-hour.png"),
        ])

        #expect(result.pdfURLs.isEmpty)
        #expect(result.crawlURLs.isEmpty)
    }

    @Test func pdfNotDuplicatedInCrawlURLs() {
        let result = filter.filter(links: [
            link(text: "Happy Hour Menu", url: "https://pub.example.com/happy-hour-menu.pdf"),
        ])

        #expect(result.pdfURLs.count == 1)
        #expect(result.crawlURLs.isEmpty)
    }

    @Test func deduplicatesDuplicateLinks() {
        let result = filter.filter(links: [
            link(text: "Specials", url: "https://pub.example.com/specials"),
            link(text: "Specials", url: "https://pub.example.com/specials/"),
        ])

        #expect(result.crawlURLs.count == 1)
    }
}
