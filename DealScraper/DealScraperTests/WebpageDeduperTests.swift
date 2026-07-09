//Created by Alex Skorulis on 9/7/2026.

import Foundation
import Testing
@testable import DealScraper

struct WebpageDeduperTests {

    private let deduper = WebpageDeduper()

    private func webpageSource(
        url: String,
        blocks: [ContentBlock]
    ) -> (URL, DiscoveredSource) {
        let pageURL = URL(string: url)!
        let source = DiscoveredSource(
            url: pageURL,
            sourceURL: pageURL,
            type: .webpage,
            textPieces: .contentBlocks(blocks)
        )
        return (pageURL, source)
    }

    private func dedupe(_ sources: [(URL, DiscoveredSource)]) -> [URL: DiscoveredSource] {
        deduper.dedupe(validatedSources: Dictionary(uniqueKeysWithValues: sources))
    }

    private func sampleBlocks(title: String = "Happy Hour") -> [ContentBlock] {
        [
            ContentBlock(
                title: title,
                text: "MON - FRI 4PM - 6PM\n$5 SCHOONERS",
                links: []
            ),
        ]
    }

    @Test func dedupesIdenticalContentBlocksKeepingFirstSeen() {
        let blocks = sampleBlocks()
        let first = webpageSource(url: "https://pub.example.com/specials", blocks: blocks)
        let second = webpageSource(url: "https://pub.example.com/happy-hour", blocks: blocks)

        let result = dedupe([first, second])

        #expect(result.count == 1)
        #expect(result[first.0] != nil)
        #expect(result[second.0] == nil)
    }

    @Test func keepsWebpagesWithDifferentContentBlocks() {
        let first = webpageSource(url: "https://pub.example.com/specials", blocks: sampleBlocks(title: "Happy Hour"))
        let second = webpageSource(
            url: "https://pub.example.com/lunch",
            blocks: sampleBlocks(title: "Lunch Special")
        )

        let result = dedupe([first, second])

        #expect(result.count == 2)
    }

    @Test func keepsWebpagesWhenLinkDiffers() {
        let sharedText = "MON - FRI 4PM - 6PM\n$5 SCHOONERS"
        let first = webpageSource(
            url: "https://pub.example.com/specials",
            blocks: [
                ContentBlock(
                    title: "Happy Hour",
                    text: sharedText,
                    links: [ContentBlockLink(text: "Book", url: URL(string: "https://pub.example.com/book")!)]
                ),
            ]
        )
        let second = webpageSource(
            url: "https://pub.example.com/happy-hour",
            blocks: [
                ContentBlock(
                    title: "Happy Hour",
                    text: sharedText,
                    links: [ContentBlockLink(text: "Book", url: URL(string: "https://pub.example.com/reserve")!)]
                ),
            ]
        )

        let result = dedupe([first, second])

        #expect(result.count == 2)
    }

    @Test func passesThroughNonWebpageSources() {
        let webpageURL = URL(string: "https://pub.example.com/specials")!
        let webpage = DiscoveredSource(
            url: webpageURL,
            sourceURL: webpageURL,
            type: .webpage,
            textPieces: .contentBlocks(sampleBlocks())
        )
        let imageURL = URL(string: "https://pub.example.com/board.png")!
        let image = DiscoveredSource(
            url: imageURL,
            sourceURL: webpageURL,
            type: .image,
            textPieces: .textLines(["HAPPY HOUR", "MON - FRI 4PM - 6PM"])
        )
        let pdfURL = URL(string: "https://pub.example.com/menu.pdf")!
        let pdf = DiscoveredSource(
            url: pdfURL,
            sourceURL: webpageURL,
            type: .pdf,
            textPieces: .textLines(["HAPPY HOUR", "MON - FRI 4PM - 6PM"])
        )

        let result = dedupe([(webpageURL, webpage), (imageURL, image), (pdfURL, pdf)])

        #expect(result.count == 3)
        #expect(result[imageURL]?.type == .image)
        #expect(result[pdfURL]?.type == .pdf)
    }

    @Test func dedupesOnlyWebpagesInMixedMap() {
        let blocks = sampleBlocks()
        let firstWebpage = webpageSource(url: "https://pub.example.com/specials", blocks: blocks)
        let duplicateWebpage = webpageSource(url: "https://pub.example.com/happy-hour", blocks: blocks)
        let imageURL = URL(string: "https://pub.example.com/board.png")!
        let image = DiscoveredSource(
            url: imageURL,
            sourceURL: firstWebpage.0,
            type: .image,
            textPieces: .textLines(["HAPPY HOUR", "MON - FRI 4PM - 6PM"])
        )

        let result = dedupe([firstWebpage, duplicateWebpage, (imageURL, image)])

        #expect(result.count == 2)
        #expect(result[firstWebpage.0] != nil)
        #expect(result[duplicateWebpage.0] == nil)
        #expect(result[imageURL] != nil)
    }
}
