//Created by Alex Skorulis on 18/6/2026.

import ASKCore
import Foundation

enum OpenRouterAPI {

    enum Error: Swift.Error, Sendable {
        case decodingFailure
    }

    nonisolated static func generateTextRequest(
        model: String,
        prompt: String,
        apiKey: String
    ) throws -> TextCompletionRequest {
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": prompt,
                ],
            ],
        ]

        return TextCompletionRequest(
            body: try JSONSerialization.data(withJSONObject: requestBody),
            headers: [
                "Authorization": "Bearer \(apiKey)",
                "Content-Type": "application/json",
                "HTTP-Referer": "https://github.com/skorulis/happy-hour",
                "X-Title": "DealScraper",
            ]
        )
    }

    nonisolated static func parseTextCompletion(from data: Data) throws -> String {
        let completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = completion.choices.first?.message.content?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !content.isEmpty
        else {
            throw Error.decodingFailure
        }
        return content
    }
}

private nonisolated struct ChatCompletionResponse: Decodable, Sendable {
    let choices: [Choice]

    struct Choice: Decodable, Sendable {
        let message: Message
    }

    struct Message: Decodable, Sendable {
        let content: String?
    }
}

struct TextCompletionRequest: HTTPRequest {
    typealias ResponseType = String

    let endpoint = "v1/chat/completions"
    let method = "POST"
    let body: Data?
    let headers: [String: String]
    let params: [String: String] = [:]

    func decode(data: Data, response: URLResponse) throws -> String {
        try OpenRouterAPI.parseTextCompletion(from: data)
    }
}
