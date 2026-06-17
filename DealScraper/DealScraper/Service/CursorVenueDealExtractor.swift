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
        let preamble = VenueDealInstructions.promptPreamble(venueName: venueName, materials: materials)
        let promptText = CursorClient.jsonPrompt(
            from: "\(instructions)\n\n\(preamble)"
        )

        let imageURLs = materials
            .filter { $0.type == .image }
            .map { $0.url.absoluteString }

        return try await client.extractVenueDeals(
            imageURLs: imageURLs,
            promptText: promptText,
            model: model,
            apiKey: apiKey
        )
    }
}
