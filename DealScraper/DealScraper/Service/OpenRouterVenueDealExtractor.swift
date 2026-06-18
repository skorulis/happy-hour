//Created by Alex Skorulis on 18/6/2026.

import Foundation

final class OpenRouterVenueDealExtractor: VenueDealExtractor, @unchecked Sendable {

    private let client: OpenRouterClient

    nonisolated init(client: OpenRouterClient) {
        self.client = client
    }

    nonisolated func extractDeals(
        materials: [VenueDealSourceMaterial],
        venueName: String,
        apiKey: String,
        model: String
    ) async -> VenueDealExtractionResult {
        let startTime = Date()
        var extractions: [SourcedDealExtraction] = []
        var errors: [VenueDealSourceExtractionError] = []

        for material in materials {
            do {
                switch material.type {
                case .image:
                    let payload = try await client.extractDeals(
                        imageReference: VisionVenueDealExtractorSupport.imageReference(for: material),
                        apiKey: apiKey,
                        model: model,
                        instructions: VisionVenueDealExtractorSupport.perSourceInstructions(
                            venueName: venueName,
                            material: material
                        )
                    )
                    extractions.append(SourcedDealExtraction(material: material, deals: payload.deals))
                case .webpage:
                    let payload = try await client.extractDealsFromWebpage(
                        url: material.url.absoluteString,
                        apiKey: apiKey,
                        model: model,
                        instructions: VisionVenueDealExtractorSupport.perSourceInstructions(
                            venueName: venueName,
                            material: material
                        )
                    )
                    extractions.append(SourcedDealExtraction(material: material, deals: payload.deals))
                case .pdf:
                    throw VisionVenueDealExtractorError.unsupportedSourceType(material.type)
                }
            } catch {
                errors.append(
                    VenueDealSourceExtractionError(
                        material: material,
                        message: error.localizedDescription
                    )
                )
            }
        }

        return VenueDealExtractionResult(
            extractions: extractions,
            errors: errors,
            duration: Date().timeIntervalSince(startTime)
        )
    }
}
