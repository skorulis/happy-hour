//Created by Alex Skorulis on 15/6/2026.

import Foundation

@MainActor
final class CrawlImageValidator {

    private let fetcher: CrawlImageFetcher
    private let imageExtractor: DealImageExtractor

    init(fetcher: CrawlImageFetcher, imageExtractor: DealImageExtractor) {
        self.fetcher = fetcher
        self.imageExtractor = imageExtractor
    }

    func isRelevantImage(url: URL, hash: String) async -> Bool {
        guard let localURL = try? await fetcher.localFileURL(for: url, hash: hash) else {
            return false
        }

        guard let lines = try? await imageExtractor.extractTexts(from: localURL) else {
            return false
        }

        return !lines.isEmpty
    }
}
