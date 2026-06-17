//Created by Alex Skorulis on 15/6/2026.

import ASKCore
import Foundation

@MainActor
final class OpenRouterClient: HTTPService {

    typealias Error = VisionDealAPI.Error

    private let urlSession: URLSessionProtocol
    private let requestHandler: ((any HTTPRequest) async throws -> DealExtractionPayload)?

    init(
        urlSession: URLSessionProtocol = URLSession(configuration: .default),
        logger: HTTPLogger? = .init(level: .full)
    ) {
        self.urlSession = urlSession
        self.requestHandler = nil
        super.init(baseURL: "https://openrouter.ai/api", logger: logger, urlSession: urlSession)
    }

    init(
        requestHandler: @escaping (any HTTPRequest) async throws -> DealExtractionPayload
    ) {
        self.urlSession = URLSession.shared
        self.requestHandler = requestHandler
        super.init(baseURL: "https://openrouter.ai/api", logger: nil)
    }

    func extractDeals(
        imageBase64: String,
        mimeType: String,
        apiKey: String,
        model: String,
        instructions: String
    ) async throws -> DealExtractionPayload {
        try await execute(request:
            OpenRouterAPI.extractDealsRequest(
                model: model,
                imageBase64: imageBase64,
                mimeType: mimeType,
                apiKey: apiKey,
                instructions: instructions
            )
        )
    }
}
