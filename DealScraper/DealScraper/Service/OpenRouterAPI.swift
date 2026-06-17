//Created by Alex Skorulis on 18/6/2026.

import ASKCore
import Foundation

enum OpenRouterAPI {

    nonisolated static func extractDealsRequest(
        model: String,
        imageBase64: String,
        mimeType: String,
        apiKey: String,
        instructions: String
    ) throws -> ExtractDealsRequest {
        let requestBody = VisionDealAPI.extractDealsRequestBody(
            model: model,
            imageBase64: imageBase64,
            mimeType: mimeType,
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
