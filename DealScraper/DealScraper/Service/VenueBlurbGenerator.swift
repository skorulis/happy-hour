//Created by Alex Skorulis on 3/7/2026.

import Foundation

enum VenueBlurbGeneratorError: LocalizedError {
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenRouter API key is not configured. Add it in Settings."
        }
    }
}

final class VenueBlurbGenerator: @unchecked Sendable {

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

    nonisolated func generateBlurb(pubName: String, suburb: String) async throws -> String {
        let apiKey = await apiKeyStore.openRouterAPIKey
        guard !apiKey.isEmpty else {
            throw VenueBlurbGeneratorError.missingAPIKey
        }

        let model = await llmModelStore.openRouterModel
        let prompt = """
            Give me a brief description of \(pubName) in \(suburb) for a directory listing.
            Source information from existing descriptions on the web.
            Do not refer to the venue by name; write as if the reader already knows what is being described.
            Do not ask any questions and write the response so it can be directly stored.
            Avoid em dashes.
            """
        return try await client.generateText(
            prompt: prompt,
            apiKey: apiKey,
            model: model
        )
    }
}
