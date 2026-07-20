//Created by Alex Skorulis on 18/6/2026.

import Foundation

final class OpenRouterVenueDealExtractor: VenueDealExtractor, @unchecked Sendable {

    private let client: ExtractDealsAPIClient
    private let backendURLStore: BackendURLStore
    private let llmModelStore: LLMModelStore

    nonisolated init(
        client: ExtractDealsAPIClient,
        backendURLStore: BackendURLStore,
        llmModelStore: LLMModelStore
    ) {
        self.client = client
        self.backendURLStore = backendURLStore
        self.llmModelStore = llmModelStore
    }

    nonisolated func extractDeals<Result>(
        materials: [VenueDealSourceMaterial],
        venueName: String,
        progress: ProgressMonitor<Result> = .empty
    ) async -> VenueDealExtractionResult {
        let startTime = Date()
        let baseURL = await backendURLStore.backendURL
        let model = await llmModelStore.openRouterModel

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
                if material.type == .pdf, material.markdown == nil {
                    throw VisionVenueDealExtractorError.missingSourceText(.pdf)
                }

                let payload = try await client.extractDeals(
                    baseURL: baseURL,
                    venueName: venueName,
                    model: model,
                    material: material
                )
                Self.logPromotionDates(from: payload)
                extractions.append(SourcedDealExtraction(material: material, deals: payload.deals))
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

    private nonisolated static func logPromotionDates(from payload: DealExtractionPayload) {
        for deal in payload.deals {
            if let dates = deal.promotionDates, !dates.isEmpty {
                print("EXTRACT: promotionDates for '\(deal.title)': \(dates)")
            }
        }
    }
}
