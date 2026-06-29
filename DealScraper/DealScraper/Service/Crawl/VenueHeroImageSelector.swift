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

    func scoreHeroImage(url: URL, venueName: String? = nil) async -> HeroImageScore {
        if Self.shouldIgnore(url: url) {
            return Self.skippedScore(skipReason: "Excluded URL pattern")
        }

        let hash = URLNormalizer.hash(url)
        guard let localURL = try? await fetcher.localFileURL(for: url, hash: hash) else {
            return Self.skippedScore(skipReason: "Could not download image")
        }

        guard let dimensions = Self.imagePixelDimensions(at: localURL) else {
            return Self.skippedScore(skipReason: "Could not read image dimensions")
        }

        guard Self.meetsMinimumDimensions(dimensions: dimensions) else {
            return Self.skippedScore(
                skipReason: "Below minimum \(Int(Self.minimumPixelDimension))×\(Int(Self.minimumPixelDimension)) pixels",
                dimensions: dimensions
            )
        }

        guard !Self.hasTransparency(at: localURL) else {
            return Self.skippedScore(skipReason: "Image has transparency", dimensions: dimensions)
        }

        let components = await scoreComponents(
            localURL: localURL,
            dimensions: dimensions,
            venueName: venueName
        )
        let isViable = HeroImageScorer.isViableCandidate(
            buildingScore: components.building,
            totalScore: components.total
        )

        return HeroImageScore(
            dimensions: dimensions,
            aspectScore: components.aspect,
            textCoverageRatio: components.coverage,
            textScore: components.text,
            buildingScore: components.building,
            venueNameScore: components.venueName,
            totalScore: components.total,
            isViable: isViable,
            skipReason: isViable ? nil : "Below viability threshold"
        )
    }

    func rankHeroImages(from urls: [URL], venueName: String? = nil) async -> [RankedHeroImage] {
        var scored: [(url: URL, score: HeroImageScore)] = []
        for url in urls {
            let score = await scoreHeroImage(url: url, venueName: venueName)
            scored.append((url, score))
        }

        scored.sort { lhs, rhs in
            if lhs.score.isViable != rhs.score.isViable {
                return lhs.score.isViable && !rhs.score.isViable
            }
            return lhs.score.totalScore > rhs.score.totalScore
        }

        return scored.enumerated().map { index, item in
            RankedHeroImage(url: item.url, score: item.score, rank: index + 1)
        }
    }

    func selectHeroImage(from urls: [URL], venueName: String? = nil) async -> URL? {
        var best: (url: URL, score: CGFloat)?

        for url in urls {
            guard !Self.shouldIgnore(url: url) else { continue }

            let hash = URLNormalizer.hash(url)
            guard let localURL = try? await fetcher.localFileURL(for: url, hash: hash) else { continue }
            guard let dimensions = Self.imagePixelDimensions(at: localURL) else { continue }
            guard Self.meetsMinimumDimensions(dimensions: dimensions) else { continue }
            guard !Self.hasTransparency(at: localURL) else { continue }

            let components = await scoreComponents(
                localURL: localURL,
                dimensions: dimensions,
                venueName: venueName
            )

            guard HeroImageScorer.isViableCandidate(
                buildingScore: components.building,
                totalScore: components.total
            ) else {
                continue
            }

            if best == nil || components.total > best!.score {
                best = (url, components.total)
            }
        }

        return best?.url
    }

    private struct ScoreComponents {
        let aspect: CGFloat
        let coverage: CGFloat
        let text: CGFloat
        let building: CGFloat
        let venueName: CGFloat
        let total: CGFloat
    }

    private func scoreComponents(
        localURL: URL,
        dimensions: CGSize,
        venueName: String?
    ) async -> ScoreComponents {
        let coverage = (try? await imageExtractor.textCoverageRatio(from: localURL)) ?? 0
        let building = (try? await classifier.buildingScore(for: localURL)) ?? 0
        let lines = (try? await imageExtractor.extractTexts(from: localURL)) ?? []
        let aspect = HeroImageScorer.aspectScore(width: dimensions.width, height: dimensions.height)
        let text = HeroImageScorer.textScore(coverageRatio: coverage)
        let venueNameScore = venueName.map {
            HeroImageScorer.venueNameScore(venueName: $0, lines: lines)
        } ?? 0
        let total = HeroImageScorer.totalScore(
            aspect: aspect,
            text: text,
            building: building,
            venueName: venueNameScore
        )

        return ScoreComponents(
            aspect: aspect,
            coverage: coverage,
            text: text,
            building: building,
            venueName: venueNameScore,
            total: total
        )
    }

    private static func skippedScore(
        skipReason: String,
        dimensions: CGSize? = nil
    ) -> HeroImageScore {
        HeroImageScore(
            dimensions: dimensions,
            aspectScore: 0,
            textCoverageRatio: 0,
            textScore: 0,
            buildingScore: 0,
            venueNameScore: 0,
            totalScore: 0,
            isViable: false,
            skipReason: skipReason
        )
    }

    private static func shouldIgnore(url: URL) -> Bool {
        if url.host() == nil {
            return true
        }
        return FilterKeywords.containsExcludedKeyword(url.absoluteString)
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

    private static func hasTransparency(at url: URL) -> Bool {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let hasAlpha = properties[kCGImagePropertyHasAlpha] as? Bool,
              hasAlpha,
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            return false
        }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var pixelData = [UInt8](repeating: 0, count: bytesPerRow * height)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: &pixelData,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: bytesPerRow,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              )
        else {
            return false
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let sampleStep = max(1, Int(sqrt(Double(width * height) / 10_000)))
        for y in stride(from: 0, to: height, by: sampleStep) {
            for x in stride(from: 0, to: width, by: sampleStep) {
                let alphaOffset = y * bytesPerRow + x * bytesPerPixel + 3
                if pixelData[alphaOffset] < 255 {
                    return true
                }
            }
        }

        return false
    }
}
