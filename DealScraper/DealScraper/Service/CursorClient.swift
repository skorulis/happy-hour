//Created by Alex Skorulis on 17/6/2026.

import ASKCore
import Foundation

@MainActor
final class CursorClient: HTTPService {

    typealias Error = VisionDealAPI.Error

    private let urlSession: URLSessionProtocol
    private let sleep: @Sendable (Duration) async throws -> Void

    private nonisolated static let pollTimeout: Duration = .seconds(120)
    private nonisolated static let initialPollDelay: Duration = .seconds(2)
    private nonisolated static let maxPollDelay: Duration = .seconds(8)

    init(
        urlSession: URLSessionProtocol = URLSession(configuration: .default),
        logger: HTTPLogger? = .init(level: .errors),
        sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        self.urlSession = urlSession
        self.sleep = sleep
        super.init(baseURL: "https://api.cursor.com" , logger: logger, urlSession: urlSession)
    }

    func extractDeals(
        imageURL: URL,
        apiKey: String,
        model: String,
        instructions: String
    ) async throws -> DealExtractionPayload {
        return try await extractVenueDeals(
            imageURLs: [imageURL.absoluteString],
            promptText: Self.jsonPrompt(from: instructions),
            model: model,
            apiKey: apiKey
        )
    }

    func extractVenueDeals(
        imageURLs: [String],
        promptText: String,
        model: String,
        apiKey: String
    ) async throws -> DealExtractionPayload {
        let (agentID, runID) = try await createAgent(
            promptText: promptText,
            imageURLs: imageURLs,
            model: model,
            apiKey: apiKey
        )

        defer {
            Task {
                try? await archiveAgent(id: agentID, apiKey: apiKey)
            }
        }

        let resultText = try await pollRun(
            agentID: agentID,
            runID: runID,
            apiKey: apiKey
        )

        guard let payload = VisionDealJSONSupport.parsePayload(from: resultText) else {
            throw Error.decodingFailure
        }

        return payload
    }

    nonisolated static func jsonPrompt(from instructions: String) -> String {
        """
        \(instructions)

        Return ONLY valid JSON with this exact shape. Do not include markdown fences or any other text:
        {"deals":[{"title":"...","details":["..."],"conditions":["..."],"days":["..."],"times":["..."],"sourceIndices":[1]}]}
        """
    }

    private func createAgent(
        promptText: String,
        imageURLs: [String],
        model: String,
        apiKey: String
    ) async throws -> (agentID: String, runID: String) {
        let response = try await execute(request:
            CursorAPI.createAgentRequest(
                apiKey: apiKey,
                promptText: promptText,
                imageURLs: imageURLs,
                model: model
            )
        )
        return (response.agent.id, response.run.id)
    }

    private func pollRun(
        agentID: String,
        runID: String,
        apiKey: String
    ) async throws -> String {
        let deadline = ContinuousClock.now + Self.pollTimeout
        var pollDelay = Self.initialPollDelay

        while ContinuousClock.now < deadline {
            try await sleep(pollDelay)
            pollDelay = min(pollDelay * 2, Self.maxPollDelay)

            let run = try await execute(request:
                CursorAPI.getRunRequest(
                    agentID: agentID,
                    runID: runID,
                    apiKey: apiKey
                )
            )

            switch run.status {
            case "FINISHED":
                guard let result = run.result, !result.isEmpty else {
                    throw Error.decodingFailure
                }
                return result
            case "ERROR", "CANCELLED", "EXPIRED":
                throw Error.apiError(
                    statusCode: 0,
                    message: "Agent run ended with status \(run.status)"
                )
            default:
                continue
            }
        }

        throw Error.apiError(statusCode: 0, message: "Agent run timed out")
    }

    private func archiveAgent(id: String, apiKey: String) async throws {
        _ = try await execute(request: CursorAPI.archiveAgentRequest(agentID: id, apiKey: apiKey))
    }

    private static func makeURLRequest<R: HTTPRequest>(from request: R) throws -> URLRequest {
        let url: URL
        if request.endpoint.starts(with: "https://") || request.endpoint.starts(with: "http://") {
            guard let parsed = URL(string: request.endpoint) else {
                throw URLError(.badURL)
            }
            url = parsed
        } else {
            throw URLError(.badURL)
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        if !request.params.isEmpty {
            components.queryItems = request.params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = request.method
        urlRequest.httpBody = request.body
        urlRequest.allHTTPHeaderFields = request.headers
        return urlRequest
    }

    private static func errorMessage(from data: Data) -> String? {
        struct APIError: Decodable {
            let message: String?
            let error: String?
        }

        let decoded = try? JSONDecoder().decode(APIError.self, from: data)
        return decoded?.message ?? decoded?.error
    }
}
