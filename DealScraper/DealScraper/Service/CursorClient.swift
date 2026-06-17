//Created by Alex Skorulis on 17/6/2026.

import Foundation

final class CursorClient: Sendable {

    typealias Error = VisionDealAPI.Error

    private let fetch: @Sendable (URLRequest) async throws -> (Data, URLResponse)
    private let sleep: @Sendable (Duration) async throws -> Void
    private let baseURL = URL(string: "https://api.cursor.com")!

    private nonisolated static let pollTimeout: Duration = .seconds(120)
    private nonisolated static let initialPollDelay: Duration = .seconds(2)
    private nonisolated static let maxPollDelay: Duration = .seconds(8)

    nonisolated init(session: URLSession = .shared) {
        self.fetch = { try await session.data(for: $0) }
        self.sleep = { try await Task.sleep(for: $0) }
    }

    nonisolated init(
        fetch: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse),
        sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        self.fetch = fetch
        self.sleep = sleep
    }

    nonisolated func extractDeals(
        imageBase64: String,
        mimeType: String,
        apiKey: String,
        model: String,
        instructions: String
    ) async throws -> DealExtractionPayload {
        try await extractVenueDeals(
            images: [(base64: imageBase64, mimeType: mimeType)],
            promptText: Self.jsonPrompt(from: instructions),
            model: model,
            apiKey: apiKey
        )
    }

    nonisolated func extractVenueDeals(
        images: [(base64: String, mimeType: String)],
        promptText: String,
        model: String,
        apiKey: String
    ) async throws -> DealExtractionPayload {
        let (agentID, runID) = try await createAgent(
            promptText: promptText,
            images: images,
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

    nonisolated private func createAgent(
        promptText: String,
        images: [(base64: String, mimeType: String)],
        model: String,
        apiKey: String
    ) async throws -> (agentID: String, runID: String) {
        let imagePayload = images.map { image in
            [
                "data": image.base64,
                "mimeType": image.mimeType,
            ] as [String: Any]
        }

        let requestBody: [String: Any] = [
            "prompt": [
                "text": promptText,
                "images": imagePayload,
            ],
            "model": [
                "id": model,
            ],
        ]

        let url = baseURL.appendingPathComponent("v1/agents")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await fetch(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw Error.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            let message = Self.errorMessage(from: data) ?? String(data: data, encoding: .utf8) ?? "Unknown error"
            throw Error.apiError(statusCode: httpResponse.statusCode, message: message)
        }

        let createResponse = try JSONDecoder().decode(CreateAgentResponse.self, from: data)
        return (createResponse.agent.id, createResponse.run.id)
    }

    nonisolated private func pollRun(
        agentID: String,
        runID: String,
        apiKey: String
    ) async throws -> String {
        let deadline = ContinuousClock.now + Self.pollTimeout
        var pollDelay = Self.initialPollDelay

        while ContinuousClock.now < deadline {
            try await sleep(pollDelay)
            pollDelay = min(pollDelay * 2, Self.maxPollDelay)

            let url = baseURL
                .appendingPathComponent("v1/agents/\(agentID)/runs/\(runID)")
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await fetch(request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw Error.invalidResponse
            }

            guard (200 ... 299).contains(httpResponse.statusCode) else {
                let message = Self.errorMessage(from: data) ?? String(data: data, encoding: .utf8) ?? "Unknown error"
                throw Error.apiError(statusCode: httpResponse.statusCode, message: message)
            }

            let run = try JSONDecoder().decode(RunResponse.self, from: data)

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

    nonisolated private func archiveAgent(id: String, apiKey: String) async throws {
        let url = baseURL.appendingPathComponent("v1/agents/\(id)/archive")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await fetch(request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200 ... 299).contains(httpResponse.statusCode)
        else {
            return
        }
    }

    nonisolated private static func errorMessage(from data: Data) -> String? {
        struct APIError: Decodable {
            let message: String?
            let error: String?
        }

        let decoded = try? JSONDecoder().decode(APIError.self, from: data)
        return decoded?.message ?? decoded?.error
    }
}

private nonisolated struct CreateAgentResponse: Decodable, Sendable {
    let agent: AgentInfo
    let run: RunInfo

    struct AgentInfo: Decodable, Sendable {
        let id: String
    }

    struct RunInfo: Decodable, Sendable {
        let id: String
    }
}

private nonisolated struct RunResponse: Decodable, Sendable {
    let status: String
    let result: String?
}
