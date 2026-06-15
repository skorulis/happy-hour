//Created by Alex Skorulis on 15/6/2026.

import Foundation

final class OpenRouterClient: Sendable {

    typealias Error = VisionDealAPI.Error

    private let fetch: @Sendable (URLRequest) async throws -> (Data, URLResponse)
    private let endpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")!

    nonisolated init(session: URLSession = .shared) {
        self.fetch = { try await session.data(for: $0) }
    }

    nonisolated init(fetch: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse)) {
        self.fetch = fetch
    }

    nonisolated func extractDeals(
        imageBase64: String,
        mimeType: String,
        apiKey: String,
        model: String,
        instructions: String
    ) async throws -> DealExtractionPayload {
        try await VisionDealAPI.extractDeals(
            endpoint: endpoint,
            model: model,
            imageBase64: imageBase64,
            mimeType: mimeType,
            apiKey: apiKey,
            instructions: instructions,
            additionalHeaders: [
                "HTTP-Referer": "https://github.com/skorulis/happy-hour",
                "X-Title": "DealScraper",
            ],
            fetch: fetch
        )
    }
}
