//Created by Alex Skorulis on 24/6/2026.

import CoreGraphics
import Foundation
import ImageIO
import Knit
import KnitMacros

@MainActor
final class VenueHeroImageSelector {

    private static let minimumPixelDimension: CGFloat = 500

    private let fetcher: CrawlImageFetcher
    private let imageExtractor: DealImageExtractor
    private let classifier: ImageClassifier

    @Resolvable<Resolver>
    init(
        fetcher: CrawlImageFetcher,
        imageExtractor: DealImageExtractor,
        classifier: ImageClassifier
    ) {
        self.fetcher = fetcher
        self.imageExtractor = imageExtractor
        self.classifier = classifier
    }

    func scoreHeroImage(url: URL) async -> HeroImageScore {
        if Self.shouldIgnore(url: url) {
            return HeroImageScore(
                dimensions: nil,
                aspectScore: 0,
                textCoverageRatio: 0,
                textScore: 0,
                buildingScore: 0,
                totalScore: 0,
                isViable: false,
                skipReason: "Excluded URL pattern"
            )
        }

        let hash = URLNormalizer.hash(url)
        guard let localURL = try? await fetcher.localFileURL(for: url, hash: hash) else {
            return HeroImageScore(
                dimensions: nil,
                aspectScore: 0,
                textCoverageRatio: 0,
                textScore: 0,
                buildingScore: 0,
                totalScore: 0,
                isViable: false,
                skipReason: "Could not download image"
            )
        }

        guard let dimensions = Self.imagePixelDimensions(at: localURL) else {
            return HeroImageScore(
                dimensions: nil,
                aspectScore: 0,
                textCoverageRatio: 0,
                textScore: 0,
                buildingScore: 0,
                totalScore: 0,
                isViable: false,
                skipReason: "Could not read image dimensions"
            )
        }

        guard Self.meetsMinimumDimensions(dimensions: dimensions) else {
            return HeroImageScore(
                dimensions: dimensions,
                aspectScore: 0,
                textCoverageRatio: 0,
                textScore: 0,
                buildingScore: 0,
                totalScore: 0,
                isViable: false,
                skipReason: "Below minimum \(Int(Self.minimumPixelDimension))×\(Int(Self.minimumPixelDimension)) pixels"
            )
        }

        let coverage = (try? await imageExtractor.textCoverageRatio(from: localURL)) ?? 0
        let building = (try? await classifier.buildingScore(for: localURL)) ?? 0
        let aspect = HeroImageScorer.aspectScore(width: dimensions.width, height: dimensions.height)
        let text = HeroImageScorer.textScore(coverageRatio: coverage)
        let total = HeroImageScorer.totalScore(aspect: aspect, text: text, building: building)
        let isViable = HeroImageScorer.isViableCandidate(buildingScore: building, totalScore: total)

        return HeroImageScore(
            dimensions: dimensions,
            aspectScore: aspect,
            textCoverageRatio: coverage,
            textScore: text,
            buildingScore: building,
            totalScore: total,
            isViable: isViable,
            skipReason: isViable ? nil : "Below viability threshold"
        )
    }

    func selectHeroImage(from urls: [URL]) async -> URL? {
        var best: (url: URL, score: CGFloat)?

        for url in urls {
            guard !Self.shouldIgnore(url: url) else { continue }

            let hash = URLNormalizer.hash(url)
            guard let localURL = try? await fetcher.localFileURL(for: url, hash: hash) else { continue }
            guard let dimensions = Self.imagePixelDimensions(at: localURL) else { continue }
            guard Self.meetsMinimumDimensions(dimensions: dimensions) else { continue }

            let coverage = (try? await imageExtractor.textCoverageRatio(from: localURL)) ?? 0
            let building = (try? await classifier.buildingScore(for: localURL)) ?? 0

            let aspect = HeroImageScorer.aspectScore(
                width: dimensions.width,
                height: dimensions.height
            )
            let text = HeroImageScorer.textScore(coverageRatio: coverage)
            let total = HeroImageScorer.totalScore(aspect: aspect, text: text, building: building)

            guard HeroImageScorer.isViableCandidate(buildingScore: building, totalScore: total) else {
                continue
            }

            if best == nil || total > best!.score {
                best = (url, total)
            }
        }

        return best?.url
    }

    private static func shouldIgnore(url: URL) -> Bool {
        if url.host() == nil {
            return true
        }
        let absoluteString = url.absoluteString.lowercased()
        return FilterKeywords.excludedKeywords.contains { absoluteString.contains($0) }
    }

    private static func meetsMinimumDimensions(dimensions: CGSize) -> Bool {
        dimensions.width >= minimumPixelDimension
            && dimensions.height >= minimumPixelDimension
    }

    private static func imagePixelDimensions(at url: URL) -> CGSize? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat
        else {
            return nil
        }

        return CGSize(width: width, height: height)
    }
}
