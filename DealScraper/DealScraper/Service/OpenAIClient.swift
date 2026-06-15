//Created by Alex Skorulis on 15/6/2026.

import Foundation

final class OpenAIClient: Sendable {

    typealias Error = VisionDealAPI.Error

    private let fetch: @Sendable (URLRequest) async throws -> (Data, URLResponse)
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

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
        instructions: String
    ) async throws -> DealExtractionPayload {
        try await VisionDealAPI.extractDeals(
            endpoint: endpoint,
            model: "gpt-4o",
            imageBase64: imageBase64,
            mimeType: mimeType,
            apiKey: apiKey,
            instructions: instructions,
            fetch: fetch
        )
    }
}
