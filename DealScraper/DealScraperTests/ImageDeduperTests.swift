//Created by Alex Skorulis on 17/6/2026.

import CoreGraphics
import Foundation
import ImageIO
import Testing
@testable import DealScraper

struct ImageDeduperTests {

    private let deduper = ImageDeduper()

    private func imageSource(
        url: String,
        lines: [String],
        dimensions: CGSize? = nil,
        featurePrint: Data? = nil,
        sourcePageURL: String = "https://pub.example.com/specials"
    ) -> (URL, DiscoveredSource) {
        let imageURL = URL(string: url)!
        let pageURL = URL(string: sourcePageURL)!
        let source = DiscoveredSource(
            url: imageURL,
            sourceURL: pageURL,
            type: .image,
            imageDimensions: dimensions,
            textPieces: .textLines(lines),
            imageFeaturePrint: featurePrint
        )
        return (imageURL, source)
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

    @Test func dedupesWhenLineSplitsDiffer() {
        let first = imageSource(
            url: "https://pub.example.com/a.png",
            lines: ["HAPPY HOUR", "MON - FRI 4PM - 6PM", "$5 SCHOONERS", "$8 WINES"]
        )
        let second = imageSource(
            url: "https://pub.example.com/b.png",
            lines: ["HAPPY HOUR MON - FRI", "4PM - 6PM", "$5 SCHOONERS", "$8 WINES"]
        )

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
            sourceURL: webpageURL,
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
        let pageURL = URL(string: "https://pub.example.com/specials")!
        let first = DiscoveredSource(url: firstURL, sourceURL: pageURL, type: .image)
        let second = DiscoveredSource(url: secondURL, sourceURL: pageURL, type: .image)

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

    @Test func dedupesViaFeaturePrintWhenOCRTextDiffers() async throws {
        let generator = ImageFeaturePrintGenerator()
        let fixtureURL = try fixtureImageURL(named: "goat_deals")
        let featurePrint = try await generator.featurePrintData(for: fixtureURL)

        let fullLines = [
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
        let partialLines = ["HAPPY HOUR", "MON - FRI 4PM - 6PM"]

        let small = imageSource(
            url: "https://pub.example.com/small.png",
            lines: partialLines,
            dimensions: CGSize(width: 600, height: 800),
            featurePrint: featurePrint
        )
        let large = imageSource(
            url: "https://pub.example.com/large.png",
            lines: fullLines,
            dimensions: CGSize(width: 1200, height: 1600),
            featurePrint: featurePrint
        )

        let result = dedupe([small, large])

        #expect(result.count == 1)
        #expect(result[large.0] != nil)
        #expect(result[small.0] == nil)
    }

    @Test func keepsVisuallyDifferentImagesWithSimilarHeaders() async throws {
        let generator = ImageFeaturePrintGenerator()
        let fixtureURL = try fixtureImageURL(named: "goat_deals")
        let otherURL = try makeSolidColorImage(width: 600, height: 800)
        let firstPrint = try await generator.featurePrintData(for: fixtureURL)
        let secondPrint = try await generator.featurePrintData(for: otherURL)

        let sharedHeader = ["HAPPY HOUR", "MON - FRI 4PM - 6PM", "$5 SCHOONERS"]
        let first = imageSource(
            url: "https://pub.example.com/a.png",
            lines: sharedHeader + ["$8 WINES", "$10 COCKTAILS"],
            featurePrint: firstPrint
        )
        let second = imageSource(
            url: "https://pub.example.com/b.png",
            lines: sharedHeader + ["COMPLETELY DIFFERENT MENU", "OTHER SPECIALS HERE"],
            featurePrint: secondPrint
        )

        let result = dedupe([first, second])

        #expect(result.count == 2)
    }

    private func fixtureImageURL(named name: String) throws -> URL {
        let bundle = Bundle(for: BundleToken.self)
        let extensions = ["jpeg", "jpg", "png"]
        for ext in extensions {
            if let url = bundle.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        throw NSError(domain: "ImageDeduperTests", code: 1)
    }

    private func makeSolidColorImage(width: Int, height: Int) throws -> URL {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let image = context.makeImage() else {
            throw ImageFeaturePrintGenerator.Error.invalidImage
        }

        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        let mutableData = CFDataCreateMutable(nil, 0)!
        guard let destination = CGImageDestinationCreateWithData(mutableData, "public.png" as CFString, 1, nil) else {
            throw ImageFeaturePrintGenerator.Error.invalidImage
        }
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
        try (mutableData as Data).write(to: destinationURL)
        return destinationURL
    }
}

private final class BundleToken {}
