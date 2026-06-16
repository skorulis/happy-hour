//Created by Alex Skorulis on 15/6/2026.

import CoreGraphics
import Foundation
import ImageIO

@MainActor
final class CrawlImageValidator {

    private static let minimumPixelDimension: CGFloat = 500

    private let fetcher: CrawlImageFetcher
    private let imageExtractor: DealImageExtractor

    init(fetcher: CrawlImageFetcher, imageExtractor: DealImageExtractor) {
        self.fetcher = fetcher
        self.imageExtractor = imageExtractor
    }

    func validateImage(url: URL, hash: String) async -> [String]? {
        guard let localURL = try? await fetcher.localFileURL(for: url, hash: hash) else {
            return nil
        }

        guard Self.meetsMinimumDimensions(at: localURL) else {
            return nil
        }

        guard let lines = try? await imageExtractor.extractTexts(from: localURL) else {
            return nil
        }

        let combinedText = lines.map(\.text).joined(separator: " ")
        guard DealDay.isMentioned(in: combinedText) else {
            return nil
        }

        return lines.map(\.text)
    }

    private static func meetsMinimumDimensions(at url: URL) -> Bool {
        guard let dimensions = imagePixelDimensions(at: url) else {
            return false
        }

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
