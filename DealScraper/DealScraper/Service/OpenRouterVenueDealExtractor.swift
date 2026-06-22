//Created by Alex Skorulis on 18/6/2026.

import Foundation

final class OpenRouterVenueDealExtractor: VenueDealExtractor, @unchecked Sendable {

    private let client: OpenRouterClient
    private let apiKeyStore: APIKeyStore
    private let llmModelStore: LLMModelStore

    nonisolated init(
        client: OpenRouterClient,
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
        let apiKey = await apiKeyStore.openRouterAPIKey
        let model = await llmModelStore.openRouterModel
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
            if Task.isCancelled {
                break
            }

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
                case .webpage:
                    let instructions = VisionVenueDealExtractorSupport.perSourceInstructions(
                        venueName: venueName,
                        material: material
                    )
                    let payload: DealExtractionPayload
                    if let markdown = material.markdown {
                        payload = try await client.extractDealsFromMarkdown(
                            markdown: markdown,
                            apiKey: apiKey,
                            model: model,
                            instructions: instructions
                        )
                    } else {
                        payload = try await client.extractDealsFromWebpage(
                            url: material.url.absoluteString,
                            apiKey: apiKey,
                            model: model,
                            instructions: instructions
                        )
                    }
                    extractions.append(SourcedDealExtraction(material: material, deals: payload.deals))
                case .pdf:
                    let instructions = VisionVenueDealExtractorSupport.perSourceInstructions(
                        venueName: venueName,
                        material: material
                    )
                    guard let text = material.markdown else {
                        throw VisionVenueDealExtractorError.missingSourceText(.pdf)
                    }
                    let payload = try await client.extractDealsFromText(
                        text: text,
                        extractionTask: VenueDealInstructions.pdfExtractionTask,
                        apiKey: apiKey,
                        model: model,
                        instructions: instructions
                    )
                    extractions.append(SourcedDealExtraction(material: material, deals: payload.deals))
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
