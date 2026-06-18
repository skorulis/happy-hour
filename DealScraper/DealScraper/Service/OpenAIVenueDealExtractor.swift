//Created by Alex Skorulis on 18/6/2026.

import Foundation

final class OpenAIVenueDealExtractor: VenueDealExtractor, @unchecked Sendable {

    private let client: OpenAIClient
    private let apiKeyStore: APIKeyStore
    private let llmModelStore: LLMModelStore

    nonisolated init(
        client: OpenAIClient,
        apiKeyStore: APIKeyStore,
        llmModelStore: LLMModelStore
    ) {
        self.client = client
        self.apiKeyStore = apiKeyStore
        self.llmModelStore = llmModelStore
    }

    nonisolated func extractDeals<Result>(
        materials: [VenueDealSourceMaterial],
        venueName: String,
        progress: ProgressMonitor<Result> = .empty
    ) async -> VenueDealExtractionResult {
        let startTime = Date()
        let apiKey = await apiKeyStore.openAIAPIKey
        let model = await llmModelStore.openAIModel
        guard !apiKey.isEmpty else {
            return VisionVenueDealExtractorSupport.missingAPIKeyResult(
                materials: materials,
                startTime: startTime
            )
        }
        
        var extractions: [SourcedDealExtraction] = []
        var errors: [VenueDealSourceExtractionError] = []
        let total = materials.count

        for (offset, material) in materials.enumerated() {
            let index = offset + 1
            await progress("Analyzing source \(index) of \(total)")

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
                case .webpage, .pdf:
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
