//Created by Alex Skorulis on 17/6/2026.

import CoreGraphics
import Foundation
import Testing
@testable import DealScraper

struct ImageDeduperTests {

    private let deduper = ImageDeduper()

    private func imageSource(
        url: String,
        lines: [String],
        dimensions: CGSize? = nil
    ) -> (URL, DiscoveredSource) {
        let sourceURL = URL(string: url)!
        let source = DiscoveredSource(
            url: sourceURL,
            type: .image,
            imageDimensions: dimensions,
            textPieces: .textLines(lines)
        )
        return (sourceURL, source)
    }

    private func dedupe(_ sources: [(URL, DiscoveredSource)]) -> [URL: DiscoveredSource] {
        deduper.dedupe(validatedSources: Dictionary(uniqueKeysWithValues: sources))
    }

    @Test func dedupesIdenticalTextLinesKeepingLargerImage() {
        let lines = [
            "HAPPY HOUR",
            "MON - FRI 4PM - 6PM",
            "$5 SCHOONERS",
            "$8 WINES",
        ]
        let small = imageSource(
            url: "https://pub.example.com/small.png",
            lines: lines,
            dimensions: CGSize(width: 600, height: 800)
        )
        let large = imageSource(
            url: "https://pub.example.com/large.png",
            lines: lines,
            dimensions: CGSize(width: 1200, height: 1600)
        )

        let result = dedupe([small, large])

        #expect(result.count == 1)
        #expect(result[large.0] != nil)
        #expect(result[small.0] == nil)
    }

    @Test func dedupesWhenMostLinesMatchWithMinorOCRTypo() {
        let baseLines = [
            "HAPPY HOUR",
            "MON - FRI 4PM - 6PM",
            "$5 SCHOONERS",
            "$8 WINES",
            "$10 COCKTAILS",
            "TUESDAY TACOS",
            "WEDNESDAY WINGS",
            "THURSDAY STEAK",
            "FRIDAY FISH",
            "SATURDAY PIZZA",
        ]
        let variantLines = baseLines.enumerated().map { index, line in
            index == 2 ? "$5 SCHOONER" : line
        }
        let first = imageSource(url: "https://pub.example.com/a.png", lines: baseLines)
        let second = imageSource(url: "https://pub.example.com/b.png", lines: variantLines)

        let result = dedupe([first, second])

        #expect(result.count == 1)
    }

    @Test func keepsImagesWhenTooFewLinesMatch() {
        let firstLines = [
            "HAPPY HOUR",
            "MON - FRI 4PM - 6PM",
            "$5 SCHOONERS",
            "$8 WINES",
            "$10 COCKTAILS",
            "TUESDAY TACOS",
            "WEDNESDAY WINGS",
            "THURSDAY STEAK",
            "FRIDAY FISH",
            "SATURDAY PIZZA",
        ]
        let secondLines = [
            "HAPPY HOUR",
            "MON - FRI 4PM - 6PM",
            "$5 SCHOONERS",
            "$8 WINES",
            "$10 COCKTAILS",
            "TUESDAY TACOS",
            "WEDNESDAY WINGS",
            "COMPLETELY DIFFERENT MENU",
            "OTHER SPECIALS HERE",
            "NOT THE SAME DEALS",
        ]
        let first = imageSource(url: "https://pub.example.com/a.png", lines: firstLines)
        let second = imageSource(url: "https://pub.example.com/b.png", lines: secondLines)

        let result = dedupe([first, second])

        #expect(result.count == 2)
    }

    @Test func dedupesWhenExtraOCRNoiseLinePresent() {
        let baseLines = [
            "HAPPY HOUR",
            "MON - FRI 4PM - 6PM",
            "$5 SCHOONERS",
            "$8 WINES",
            "$10 COCKTAILS",
            "TUESDAY TACOS",
            "WEDNESDAY WINGS",
            "THURSDAY STEAK",
            "FRIDAY FISH",
            "SATURDAY PIZZA",
        ]
        let noisyLines = baseLines + ["EST. 1862"]
        let first = imageSource(url: "https://pub.example.com/a.png", lines: baseLines)
        let second = imageSource(url: "https://pub.example.com/b.png", lines: noisyLines)

        let result = dedupe([first, second])

        #expect(result.count == 1)
    }

    @Test func keepsDifferentDealContent() {
        let first = imageSource(
            url: "https://pub.example.com/happy-hour.png",
            lines: ["HAPPY HOUR", "MON - FRI 4PM - 6PM", "$5 SCHOONERS"]
        )
        let second = imageSource(
            url: "https://pub.example.com/lunch.png",
            lines: ["LUNCH SPECIAL", "MON - FRI 12PM - 2PM", "$15 BURGERS"]
        )

        let result = dedupe([first, second])

        #expect(result.count == 2)
    }

    @Test func passesThroughNonImageSources() {
        let webpageURL = URL(string: "https://pub.example.com/specials")!
        let webpage = DiscoveredSource(
            url: webpageURL,
            type: .webpage,
            textPieces: .textLines(["Weekly Specials"])
        )
        let image = imageSource(
            url: "https://pub.example.com/board.png",
            lines: ["HAPPY HOUR", "MON - FRI 4PM - 6PM"]
        )

        let result = dedupe([(webpageURL, webpage), image])

        #expect(result.count == 2)
        #expect(result[webpageURL]?.type == .webpage)
    }

    @Test func keepsImagesWithEmptyTextSeparately() {
        let firstURL = URL(string: "https://pub.example.com/a.png")!
        let secondURL = URL(string: "https://pub.example.com/b.png")!
        let first = DiscoveredSource(url: firstURL, type: .image)
        let second = DiscoveredSource(url: secondURL, type: .image)

        let result = deduper.dedupe(validatedSources: [
            firstURL: first,
            secondURL: second,
        ])

        #expect(result.count == 2)
    }

    @Test func replacesSmallerDuplicateWithLargerCandidate() {
        let lines = ["HAPPY HOUR", "MON - FRI 4PM - 6PM", "$5 SCHOONERS"]
        let large = imageSource(
            url: "https://pub.example.com/large.png",
            lines: lines,
            dimensions: CGSize(width: 1200, height: 1600)
        )
        let small = imageSource(
            url: "https://pub.example.com/small.png",
            lines: lines,
            dimensions: CGSize(width: 600, height: 800)
        )

        let result = dedupe([large, small])

        #expect(result.count == 1)
        #expect(result[large.0] != nil)
        #expect(result[small.0] == nil)
    }
}
