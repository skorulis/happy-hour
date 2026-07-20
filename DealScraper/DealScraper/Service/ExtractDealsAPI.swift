//Created by Alex Skorulis on 20/7/2026.

import ASKCore
import Foundation

enum ExtractDealsAPI {

    enum Error: Swift.Error, LocalizedError, Sendable {
        case invalidBackendURL(String)
        case apiError(statusCode: Int, message: String)
        case decodingFailure

        var errorDescription: String? {
            switch self {
            case let .invalidBackendURL(url):
                return "Invalid backend URL: \(url)"
            case let .apiError(_, message):
                return message
            case .decodingFailure:
                return "Failed to decode extract-deals response."
            }
        }
    }

    nonisolated static func extractDealsRequest(
        baseURL: String,
        venueName: String,
        model: String,
        material: VenueDealSourceMaterial
    ) throws -> BackendExtractDealsRequest {
        let trimmedBase = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let root = URL(string: trimmedBase), root.scheme != nil, root.host != nil else {
            throw Error.invalidBackendURL(baseURL)
        }

        let endpoint = root
            .appendingPathComponent("api")
            .appendingPathComponent("extract-deals")
            .absoluteString

        var source: [String: Any] = [
            "type": material.type.rawValue,
            "index": material.index,
            "url": material.url.absoluteString,
            "sourceURL": material.sourceURL.absoluteString,
        ]

        switch material.type {
        case .image:
            if let pngData = material.pngData {
                source["imageBase64"] = pngData.base64EncodedString()
                source["mimeType"] = "image/png"
            } else {
                source["imageUrl"] = material.url.absoluteString
            }
        case .webpage:
            if let markdown = material.markdown {
                source["markdown"] = markdown
            }
        case .pdf:
            guard let text = material.markdown else {
                throw VisionVenueDealExtractorError.missingSourceText(.pdf)
            }
            source["text"] = text
        }

        let bodyObject: [String: Any] = [
            "venueName": venueName,
            "model": model,
            "source": source,
        ]

        return BackendExtractDealsRequest(
            endpoint: endpoint,
            body: try JSONSerialization.data(withJSONObject: bodyObject),
            headers: [
                "Content-Type": "application/json",
                "Accept": "application/json",
            ]
        )
    }
}

struct BackendExtractDealsRequest: HTTPRequest {
    typealias ResponseType = DealExtractionPayload

    let endpoint: String
    let method = "POST"
    let body: Data?
    let headers: [String: String]
    let params: [String: String] = [:]

    func decode(data: Data, response: URLResponse) throws -> DealExtractionPayload {
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        if !(200..<300).contains(statusCode) {
            if let errorBody = try? JSONDecoder().decode(APIErrorBody.self, from: data),
               !errorBody.error.isEmpty {
                throw ExtractDealsAPI.Error.apiError(statusCode: statusCode, message: errorBody.error)
            }
            throw ExtractDealsAPI.Error.apiError(
                statusCode: statusCode,
                message: "extract-deals failed (\(statusCode))"
            )
        }

        do {
            return try JSONDecoder().decode(DealExtractionPayload.self, from: data)
        } catch {
            throw ExtractDealsAPI.Error.decodingFailure
        }
    }
}

private nonisolated struct APIErrorBody: Decodable, Sendable {
    let error: String
}
