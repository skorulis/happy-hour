//Created by Alex Skorulis on 18/6/2026.

import ASKCore
import Foundation

enum OpenRouterAPI {

    nonisolated static func extractDealsRequest(
        model: String,
        imageReference: VisionDealAPI.ImageReference,
        apiKey: String,
        instructions: String
    ) throws -> ExtractDealsRequest {
        let requestBody = VisionDealAPI.extractDealsRequestBody(
            model: model,
            imageReference: imageReference,
            instructions: instructions
        )

        return ExtractDealsRequest(
            body: try JSONSerialization.data(withJSONObject: requestBody),
            headers: [
                "Authorization": "Bearer \(apiKey)",
                "Content-Type": "application/json",
                "HTTP-Referer": "https://github.com/skorulis/happy-hour",
                "X-Title": "DealScraper",
            ]
        )
    }

    nonisolated static func extractDealsRequest(
        model: String,
        imageBase64: String,
        mimeType: String,
        apiKey: String,
        instructions: String
    ) throws -> ExtractDealsRequest {
        try extractDealsRequest(
            model: model,
            imageReference: .base64(data: imageBase64, mimeType: mimeType),
            apiKey: apiKey,
            instructions: instructions
        )
    }

    nonisolated static func extractWebpageDealsRequest(
        model: String,
        webpageURL: String,
        apiKey: String,
        instructions: String
    ) throws -> ExtractDealsRequest {
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": instructions,
                ],
                [
                    "role": "user",
                    "content": """
                    \(VenueDealInstructions.webpageExtractionTask)

                    \(webpageURL)
                    """,
                ],
            ],
            "tools": [
                [
                    "type": "openrouter:web_fetch",
                    "parameters": [
                        "max_uses": 1,
                    ],
                ],
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "deal_extraction",
                    "strict": true,
                    "schema": VisionDealAPI.dealExtractionSchema,
                ],
            ],
        ]

        return ExtractDealsRequest(
            body: try JSONSerialization.data(withJSONObject: requestBody),
            headers: [
                "Authorization": "Bearer \(apiKey)",
                "Content-Type": "application/json",
                "HTTP-Referer": "https://github.com/skorulis/happy-hour",
                "X-Title": "DealScraper",
            ]
        )
    }

    nonisolated static func extractMarkdownDealsRequest(
        model: String,
        markdown: String,
        apiKey: String,
        instructions: String
    ) throws -> ExtractDealsRequest {
        try extractTextDealsRequest(
            model: model,
            text: markdown,
            extractionTask: VenueDealInstructions.markdownExtractionTask,
            apiKey: apiKey,
            instructions: instructions
        )
    }

    nonisolated static func extractTextDealsRequest(
        model: String,
        text: String,
        extractionTask: String,
        apiKey: String,
        instructions: String
    ) throws -> ExtractDealsRequest {
        let requestBody = VisionDealAPI.extractTextDealsRequestBody(
            model: model,
            text: text,
            extractionTask: extractionTask,
            instructions: instructions
        )

        return ExtractDealsRequest(
            body: try JSONSerialization.data(withJSONObject: requestBody),
            headers: [
                "Authorization": "Bearer \(apiKey)",
                "Content-Type": "application/json",
                "HTTP-Referer": "https://github.com/skorulis/happy-hour",
                "X-Title": "DealScraper",
            ]
        )
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
            throw VisionDealAPI.Error.decodingFailure
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

struct ExtractDealsRequest: HTTPRequest {
    typealias ResponseType = DealExtractionPayload

    let endpoint = "v1/chat/completions"
    let method = "POST"
    let body: Data?
    let headers: [String: String]
    let params: [String: String] = [:]

    func decode(data: Data, response: URLResponse) throws -> DealExtractionPayload {
        try VisionDealAPI.parseDealExtractionPayload(from: data)
    }
}
