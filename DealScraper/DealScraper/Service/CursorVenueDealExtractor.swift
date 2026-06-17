//Created by Alex Skorulis on 17/6/2026.

import Foundation

final class CursorVenueDealExtractor: VenueDealExtractor, Sendable {

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
        let preamble = VenueDealInstructions.promptPreamble(venueName: venueName, materials: materials)
        let promptText = CursorClient.jsonPrompt(
            from: "\(instructions)\n\n\(preamble)"
        )

        let images = materials.compactMap { material -> (base64: String, mimeType: String)? in
            guard let pngData = material.pngData else { return nil }
            return (base64: pngData.base64EncodedString(), mimeType: "image/png")
        }

        return try await client.extractVenueDeals(
            images: images,
            promptText: promptText,
            model: model,
            apiKey: apiKey
        )
    }
}
