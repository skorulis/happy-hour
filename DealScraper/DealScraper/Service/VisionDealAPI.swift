//Created by Alex Skorulis on 15/6/2026.

import Foundation

enum VisionDealAPI {

    enum Error: Swift.Error, Sendable {
        case invalidResponse
        case apiError(statusCode: Int, message: String)
        case decodingFailure
    }

    enum ImageReference: Sendable {
        case base64(data: String, mimeType: String)
        case url(String)
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
                        "conditions": [
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
                    "required": ["title", "details", "conditions", "days", "times"],
                    "additionalProperties": false,
                ],
            ],
        ],
        "required": ["deals"],
        "additionalProperties": false,
    ]

    nonisolated static func extractDealsRequestBody(
        model: String,
        imageReference: ImageReference,
        instructions: String
    ) -> [String: Any] {
        let imageURLString: String
        switch imageReference {
        case let .base64(data, mimeType):
            imageURLString = "data:\(mimeType);base64,\(data)"
        case let .url(url):
            imageURLString = url
        }

        return [
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
                                "url": imageURLString,
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
    }

    nonisolated static func extractDealsRequestBody(
        model: String,
        imageBase64: String,
        mimeType: String,
        instructions: String
    ) -> [String: Any] {
        extractDealsRequestBody(
            model: model,
            imageReference: .base64(data: imageBase64, mimeType: mimeType),
            instructions: instructions
        )
    }

    nonisolated static func extractTextDealsRequestBody(
        model: String,
        text: String,
        extractionTask: String,
        instructions: String
    ) -> [String: Any] {
        [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": instructions,
                ],
                [
                    "role": "user",
                    "content": """
                    \(extractionTask)

                    \(text)
                    """,
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
    }

    nonisolated static func parseDealExtractionPayload(from data: Data) throws -> DealExtractionPayload {
        let completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = completion.choices.first?.message.content else {
            throw Error.decodingFailure
        }

        let jsonString = stripMarkdownCodeFence(from: content)
        guard let payloadData = jsonString.data(using: .utf8) else {
            throw Error.decodingFailure
        }

        if let payload = try? JSONDecoder().decode(DealExtractionPayload.self, from: payloadData) {
            return payload
        }

        if let deals = try? JSONDecoder().decode([DealExtractionPayload.RawDeal].self, from: payloadData) {
            return DealExtractionPayload(deals: deals)
        }

        throw Error.decodingFailure
    }

    nonisolated static func stripMarkdownCodeFence(from content: String) -> String {
        var trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("```") else { return trimmed }

        if let firstNewline = trimmed.firstIndex(of: "\n") {
            trimmed = String(trimmed[trimmed.index(after: firstNewline)...])
        }
        if trimmed.hasSuffix("```") {
            trimmed = String(trimmed.dropLast(3))
        }
        return trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated static func extractDeals(
        endpoint: URL,
        model: String,
        imageReference: ImageReference,
        apiKey: String,
        instructions: String,
        additionalHeaders: [String: String] = [:],
        fetch: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse)
    ) async throws -> DealExtractionPayload {
        let requestBody = extractDealsRequestBody(
            model: model,
            imageReference: imageReference,
            instructions: instructions
        )

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

        return try parseDealExtractionPayload(from: data)
    }

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
        try await extractDeals(
            endpoint: endpoint,
            model: model,
            imageReference: .base64(data: imageBase64, mimeType: mimeType),
            apiKey: apiKey,
            instructions: instructions,
            additionalHeaders: additionalHeaders,
            fetch: fetch
        )
    }

    nonisolated static func extractDealsFromText(
        endpoint: URL,
        model: String,
        text: String,
        extractionTask: String,
        apiKey: String,
        instructions: String,
        additionalHeaders: [String: String] = [:],
        fetch: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse)
    ) async throws -> DealExtractionPayload {
        let requestBody = extractTextDealsRequestBody(
            model: model,
            text: text,
            extractionTask: extractionTask,
            instructions: instructions
        )

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

        return try parseDealExtractionPayload(from: data)
    }

    nonisolated static func errorMessage(from data: Data) -> String? {
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
