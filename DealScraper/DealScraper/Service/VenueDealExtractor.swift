//Created by Alex Skorulis on 17/6/2026.

import Foundation

protocol VenueDealExtractor: Sendable {
    func extractDeals<Result>(
        materials: [VenueDealSourceMaterial],
        venueName: String,
        progress: ProgressMonitor<Result>
    ) async -> VenueDealExtractionResult
}
