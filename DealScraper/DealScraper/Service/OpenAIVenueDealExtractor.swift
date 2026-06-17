//Created by Alex Skorulis on 18/6/2026.

import Foundation

final class OpenAIVenueDealExtractor: VenueDealExtractor, @unchecked Sendable {

    private let client: OpenAIClient

    nonisolated init(client: OpenAIClient) {
        self.client = client
    }

    nonisolated func extractDeals(
        materials: [VenueDealSourceMaterial],
        venueName: String,
        instructions: String,
        apiKey: String,
        model: String
    ) async throws -> DealExtractionPayload {
        var allDeals: [DealExtractionPayload.RawDeal] = []

        for material in materials {
            switch material.type {
            case .image:
                let payload = try await client.extractDeals(
                    imageReference: VisionVenueDealExtractorSupport.imageReference(for: material),
                    apiKey: apiKey,
                    model: model,
                    instructions: VisionVenueDealExtractorSupport.perSourceInstructions(
                        instructions: instructions,
                        venueName: venueName,
                        material: material
                    )
                )
                allDeals.append(contentsOf: VisionVenueDealExtractorSupport.normalizeSourceIndices(
                    payload.deals,
                    fallbackIndex: material.index
                ))
            case .webpage, .pdf:
                throw VisionVenueDealExtractorError.unsupportedSourceType(material.type)
            }
        }

        return DealExtractionPayload(deals: allDeals)
    }
}
