//Created by Alex Skorulis on 15/6/2026.

import ASKCore
import Foundation

@MainActor
final class OpenRouterClient: HTTPService {

    init(
        urlSession: URLSessionProtocol = URLSession(configuration: .default),
        logger: HTTPLogger? = .init(level: .full)
    ) {
        super.init(baseURL: "https://openrouter.ai/api", logger: logger, urlSession: urlSession)
    }

    func generateText(
        prompt: String,
        apiKey: String,
        model: String
    ) async throws -> String {
        try await execute(request:
            OpenRouterAPI.generateTextRequest(
                model: model,
                prompt: prompt,
                apiKey: apiKey
            )
        )
    }
}
