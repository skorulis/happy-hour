//Created by Alex Skorulis on 15/6/2026.

import ASKCore
import Foundation

@MainActor
final class OpenRouterClient: HTTPService {

    typealias Error = VisionDealAPI.Error

    init(
        urlSession: URLSessionProtocol = URLSession(configuration: .default),
        logger: HTTPLogger? = .init(level: .full)
    ) {
        super.init(baseURL: "https://openrouter.ai/api", logger: logger, urlSession: urlSession)
    }

    func extractDeals(
        imageReference: VisionDealAPI.ImageReference,
        apiKey: String,
        model: String,
        instructions: String
    ) async throws -> DealExtractionPayload {
        try await execute(request:
            OpenRouterAPI.extractDealsRequest(
                model: model,
                imageReference: imageReference,
                apiKey: apiKey,
                instructions: instructions
            )
        )
    }

    func extractDeals(
        imageBase64: String,
        mimeType: String,
        apiKey: String,
        model: String,
        instructions: String
    ) async throws -> DealExtractionPayload {
        try await extractDeals(
            imageReference: .base64(data: imageBase64, mimeType: mimeType),
            apiKey: apiKey,
            model: model,
            instructions: instructions
        )
    }

    func extractDealsFromWebpage(
        url: String,
        apiKey: String,
        model: String,
        instructions: String
    ) async throws -> DealExtractionPayload {
        try await execute(request:
            OpenRouterAPI.extractWebpageDealsRequest(
                model: model,
                webpageURL: url,
                apiKey: apiKey,
                instructions: instructions
            )
        )
    }

    func extractDealsFromMarkdown(
        markdown: String,
        apiKey: String,
        model: String,
        instructions: String
    ) async throws -> DealExtractionPayload {
        try await execute(request:
            OpenRouterAPI.extractMarkdownDealsRequest(
                model: model,
                markdown: markdown,
                apiKey: apiKey,
                instructions: instructions
            )
        )
    }
}
