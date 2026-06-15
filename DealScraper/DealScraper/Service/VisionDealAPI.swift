//Created by Alex Skorulis on 15/6/2026.

import Foundation

enum VisionDealAPI {

    enum Error: Swift.Error, Sendable {
        case invalidResponse
        case apiError(statusCode: Int, message: String)
        case decodingFailure
    }

    nonisolated(unsafe) static let dealExtractionSchema: [String: Any] = [
        "type": "object",
        "properties": [
            "deals": [
                "type": "array",
                "items": [
                    "type": "object",
                    "properties": [
                        "title": ["type": "string"],
                        "details": [
                            "type": "array",
                            "items": ["type": "string"],
                        ],
                        "days": [
                            "type": "array",
                            "items": ["type": "string"],
                        ],
                        "times": [
                            "type": "array",
                            "items": ["type": "string"],
                        ],
                    ],
                    "required": ["title", "details", "days", "times"],
                    "additionalProperties": false,
                ],
            ],
        ],
        "required": ["deals"],
        "additionalProperties": false,
    ]

    nonisolated static func extractDeals(
        endpoint: URL,
        model: String,
        imageBase64: String,
        mimeType: String,
        apiKey: String,
        instructions: String,
        additionalHeaders: [String: String] = [:],
        fetch: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse)
    ) async throws -> DealExtractionPayload {
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": instructions,
                ],
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": "Extract all deals from this pub or restaurant poster image.",
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:\(mimeType);base64,\(imageBase64)",
                            ],
                        ],
                    ],
                ],
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "deal_extraction",
                    "strict": true,
                    "schema": dealExtractionSchema,
                ],
            ],
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (key, value) in additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await fetch(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw Error.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            let message = errorMessage(from: data) ?? String(data: data, encoding: .utf8) ?? "Unknown error"
            print("VisionDealAPI Error: \(message)")
            throw Error.apiError(statusCode: httpResponse.statusCode, message: message)
        }

        let completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = completion.choices.first?.message.content else {
            throw Error.decodingFailure
        }

        guard let payloadData = content.data(using: .utf8),
              let payload = try? JSONDecoder().decode(DealExtractionPayload.self, from: payloadData)
        else {
            throw Error.decodingFailure
        }

        return payload
    }

    nonisolated private static func errorMessage(from data: Data) -> String? {
        struct APIError: Decodable {
            struct Detail: Decodable {
                let message: String
            }

            let error: Detail
        }

        return (try? JSONDecoder().decode(APIError.self, from: data))?.error.message
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
