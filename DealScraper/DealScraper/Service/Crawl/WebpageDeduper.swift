//Created by Alex Skorulis on 9/7/2026.

import Foundation

struct WebpageDeduper: Sendable {

    func dedupe(validatedSources: [URL: DiscoveredSource]) -> [URL: DiscoveredSource] {
        var result: [URL: DiscoveredSource] = [:]
        var keptWebpages: [KeptWebpage] = []

        for (url, source) in validatedSources {
            guard source.type == .webpage else {
                result[url] = source
                continue
            }

            guard let blocks = contentBlocks(from: source.textPieces) else {
                result[url] = source
                continue
            }

            if let existing = keptWebpages.first(where: { $0.source.contentHash == source.contentHash }) {
                print("CRAWL: Dropping duplicate webpage \(url) — same contentBlocks as \(existing.url)")
                continue
            }

            keptWebpages.append(KeptWebpage(url: url, source: source, blocks: blocks))
            result[url] = source
        }

        return result
    }

    private struct KeptWebpage {
        let url: URL
        let source: DiscoveredSource
        let blocks: [ContentBlock]
    }

    private func contentBlocks(from textPieces: DealSourceTextPieces?) -> [ContentBlock]? {
        guard let textPieces else { return nil }
        switch textPieces {
        case let .contentBlocks(blocks):
            return blocks
        case .textLines:
            return nil
        }
    }
}
