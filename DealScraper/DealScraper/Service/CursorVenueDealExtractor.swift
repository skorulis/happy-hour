//Created by Alex Skorulis on 17/6/2026.

import Foundation

final class CursorVenueDealExtractor: VenueDealExtractor, @unchecked Sendable {

    private let client: CursorClient

    nonisolated init(client: CursorClient) {
        self.client = client
    }

    nonisolated func extractDeals(
        materials: [VenueDealSourceMaterial],
        venueName: String,
        instructions: String,
        apiKey: String,
        model: String
    ) async throws -> DealExtractionPayload {
        guard let firstMaterial = materials.first else {
            return DealExtractionPayload(deals: [])
        }

        let (agentID, firstRunID) = try await client.createAgentRun(
            promptText: Self.perSourcePrompt(
                instructions: instructions,
                venueName: venueName,
                material: firstMaterial
            ),
            imageURLs: Self.imageURLs(for: firstMaterial),
            model: model,
            apiKey: apiKey
        )

        defer {
            Task {
                await client.archiveAgent(id: agentID, apiKey: apiKey)
            }
        }

        var allDeals: [DealExtractionPayload.RawDeal] = []

        let firstPayload = try await client.pollRunForPayload(
            agentID: agentID,
            runID: firstRunID,
            apiKey: apiKey
        )
        allDeals.append(contentsOf: Self.normalizeSourceIndices(
            firstPayload.deals,
            fallbackIndex: firstMaterial.index
        ))

        for material in materials.dropFirst() {
            let payload = try await client.extractVenueDeals(
                agentID: agentID,
                imageURLs: Self.imageURLs(for: material),
                promptText: Self.perSourcePrompt(
                    instructions: instructions,
                    venueName: venueName,
                    material: material
                ),
                model: model,
                apiKey: apiKey
            )
            allDeals.append(contentsOf: Self.normalizeSourceIndices(
                payload.deals,
                fallbackIndex: material.index
            ))
        }

        return DealExtractionPayload(deals: allDeals)
    }

    private nonisolated static func imageURLs(for material: VenueDealSourceMaterial) -> [String] {
        material.type == .image ? [material.url.absoluteString] : []
    }

    private nonisolated static func perSourcePrompt(
        instructions: String,
        venueName: String,
        material: VenueDealSourceMaterial
    ) -> String {
        CursorClient.jsonPrompt(
            from: perSourceInstructions(
                instructions: instructions,
                venueName: venueName,
                material: material
            )
        )
    }

    private nonisolated static func perSourceInstructions(
        instructions: String,
        venueName: String,
        material: VenueDealSourceMaterial
    ) -> String {
        let preamble = VenueDealInstructions.promptPreamble(
            venueName: venueName,
            materials: [material]
        )
        return """
        \(instructions)

        \(preamble)

        Only extract deals visible in Source \(material.index).
        Set sourceIndices to [\(material.index)] for each returned deal.
        """
    }

    private nonisolated static func normalizeSourceIndices(
        _ deals: [DealExtractionPayload.RawDeal],
        fallbackIndex: Int
    ) -> [DealExtractionPayload.RawDeal] {
        deals.map { deal in
            let normalizedIndices = deal.sourceIndices.isEmpty ? [fallbackIndex] : deal.sourceIndices
            return .init(
                title: deal.title,
                details: deal.details,
                conditions: deal.conditions,
                days: deal.days,
                times: deal.times,
                sourceIndices: normalizedIndices
            )
        }
    }
}
