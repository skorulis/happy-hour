//Created by Alex Skorulis on 15/6/2026.

import Knit
import KnitMacros
import CoreGraphics
import Foundation
import ImageIO

@MainActor
final class CrawlImageValidator {

    private static let minimumPixelDimension: CGFloat = 500

    private let fetcher: CrawlImageFetcher
    private let imageExtractor: DealImageExtractor
    private let featurePrintGenerator: ImageFeaturePrintGenerator

    @Resolvable<Resolver>
    init(
        fetcher: CrawlImageFetcher,
        imageExtractor: DealImageExtractor,
        featurePrintGenerator: ImageFeaturePrintGenerator
    ) {
        self.fetcher = fetcher
        self.imageExtractor = imageExtractor
        self.featurePrintGenerator = featurePrintGenerator
    }

    func validateImage(url: URL) async -> ImageValidationResult? {
        guard !Self.shouldIgnore(url: url) else {
            return nil
        }

        let hash = URLNormalizer.hash(url)
        guard let localURL = try? await fetcher.localFileURL(for: url, hash: hash) else {
            return nil
        }

        guard let dimensions = Self.imagePixelDimensions(at: localURL) else {
            return nil
        }
        guard Self.meetsMinimumDimensions(dimensions: dimensions) else {
            return nil
        }

        guard let lines = try? await imageExtractor.extractTexts(from: localURL) else {
            return nil
        }
        
        let combinedText = lines.map(\.text).joined(separator: "\n")
        guard DealTextFilter().isValidDeal(combinedText) else {
            return nil
        }

        let featurePrint = try? await featurePrintGenerator.featurePrintData(for: localURL)

        return .init(
            url: url,
            lines: lines,
            dimensions: dimensions,
            featurePrint: featurePrint
        )
    }

    func validateImages(urls: [URL]) async -> [ImageValidationResult] {
        var results: [ImageValidationResult] = []
        for url in urls {
            if let validation = await validateImage(url: url) {
                results.append(validation)
            }
        }
        return results
    }

    private static func shouldIgnore(url: URL) -> Bool {
        if url.host() == nil {
            return true
        }
        let absoluteString = url.absoluteString.lowercased()
        return FilterKeywords.excludedKeywords.contains { absoluteString.contains($0) }
    }

    private static func meetsMinimumDimensions(dimensions: CGSize) -> Bool {
        return dimensions.width >= minimumPixelDimension
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

struct ImageValidationResult {
    let url: URL
    let lines: [ExtractedTextLine]
    let dimensions: CGSize
    let featurePrint: Data?
}
