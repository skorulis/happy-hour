//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Knit
import KnitMacros

struct OnDeviceDealProcessor: DealProcessing, Sendable {

    let imageExtractor: DealImageExtractor
    let textAnalyzer: DealTextAnalyzer

    @Resolvable<Resolver>
    init(
        imageExtractor: DealImageExtractor,
        textAnalyzer: DealTextAnalyzer
    ) {
        self.imageExtractor = imageExtractor
        self.textAnalyzer = textAnalyzer
    }

    nonisolated func extractDeals(from url: URL) async throws -> [LegacyDeal] {
        let lines = try await imageExtractor.extractTexts(from: url)
        return try await textAnalyzer.analyze(lines: lines)
    }
}
