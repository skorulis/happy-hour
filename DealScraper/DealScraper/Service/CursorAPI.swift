//Created by Alex Skorulis on 17/6/2026.

import ASKCore
import Foundation

enum CursorAPI {

    nonisolated static func createAgentRequest(
        apiKey: String,
        promptText: String,
        imageURLs: [String],
        model: String
    ) -> HTTPJSONRequest<CreateAgentResponse> {
        var request = HTTPJSONRequest<CreateAgentResponse>(
            endpoint: "v1/agents",
            body: CreateAgentBody(
                prompt: .init(
                    text: promptText,
                    images: imageURLs.map { .init(url: $0) }
                ),
                model: .init(id: model)
            )
        )
        request.headers["Authorization"] = "Bearer \(apiKey)"
        return request
    }

    nonisolated static func getRunRequest(
        agentID: String,
        runID: String,
        apiKey: String
    ) -> HTTPJSONRequest<RunResponse> {
        var request = HTTPJSONRequest<RunResponse>(
            endpoint: "v1/agents/\(agentID)/runs/\(runID)"
        )
        request.headers["Authorization"] = "Bearer \(apiKey)"
        return request
    }

    nonisolated static func archiveAgentRequest(
        agentID: String,
        apiKey: String
    ) -> ArchiveAgentRequest {
        ArchiveAgentRequest(
            endpoint: "v1/agents/\(agentID)/archive",
            headers: ["Authorization": "Bearer \(apiKey)"]
        )
    }
}

nonisolated struct CreateAgentResponse: Decodable, Sendable {
    let agent: AgentInfo
    let run: RunInfo

    struct AgentInfo: Decodable, Sendable {
        let id: String
    }

    struct RunInfo: Decodable, Sendable {
        let id: String
    }
}

nonisolated struct RunResponse: Decodable, Sendable {
    let status: String
    let result: String?
}

struct ArchiveAgentRequest: HTTPRequest {
    typealias ResponseType = Void

    let endpoint: String
    let method: String = "POST"
    let body: Data? = nil
    let headers: [String: String]
    let params: [String: String] = [:]

    func decode(data: Data, response: URLResponse) throws {}
}

private struct CreateAgentBody: Encodable, Sendable {
    let prompt: Prompt
    let model: Model

    struct Prompt: Encodable, Sendable {
        let text: String
        let images: [Image]
    }

    struct Image: Encodable, Sendable {
        let url: String
    }

    struct Model: Encodable, Sendable {
        let id: String
    }
}
