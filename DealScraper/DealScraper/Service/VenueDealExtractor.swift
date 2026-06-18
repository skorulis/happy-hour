//Created by Alex Skorulis on 17/6/2026.

import Foundation

protocol VenueDealExtractor: Sendable {
    func extractDeals(
        materials: [VenueDealSourceMaterial],
        venueName: String,
        apiKey: String,
        model: String
    ) async throws -> [SourcedDealExtraction]
}
