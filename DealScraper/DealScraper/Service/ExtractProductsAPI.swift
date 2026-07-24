//Created by Alex Skorulis on 24/7/2026.

import ASKCore
import Foundation

enum ExtractProductsAPI {

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
                return "Failed to decode extract-products response."
            }
        }
    }

    nonisolated static func extractProductsRequest(
        baseURL: String,
        title: String?,
        details: String?
    ) throws -> BackendExtractProductsRequest {
        let trimmedBase = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let root = URL(string: trimmedBase), root.scheme != nil, root.host != nil else {
            throw Error.invalidBackendURL(baseURL)
        }

        let endpoint = root
            .appendingPathComponent("api")
            .appendingPathComponent("extract-products")
            .absoluteString

        let bodyObject: [String: Any] = [
            "title": title as Any? ?? NSNull(),
            "details": details as Any? ?? NSNull(),
        ]

        return BackendExtractProductsRequest(
            endpoint: endpoint,
            body: try JSONSerialization.data(withJSONObject: bodyObject),
            headers: [
                "Content-Type": "application/json",
                "Accept": "application/json",
            ]
        )
    }
}

struct ExtractProductsPayload: Decodable, Sendable {
    let products: [ExtractedProductPayload]
}

struct ExtractedProductPayload: Decodable, Sendable {
    let name: String
    let price: Double?
}

struct BackendExtractProductsRequest: HTTPRequest {
    typealias ResponseType = ExtractProductsPayload

    let endpoint: String
    let method = "POST"
    let body: Data?
    let headers: [String: String]
    let params: [String: String] = [:]

    func decode(data: Data, response: URLResponse) throws -> ExtractProductsPayload {
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        if !(200..<300).contains(statusCode) {
            if let errorBody = try? JSONDecoder().decode(APIErrorBody.self, from: data),
               !errorBody.error.isEmpty {
                throw ExtractProductsAPI.Error.apiError(statusCode: statusCode, message: errorBody.error)
            }
            throw ExtractProductsAPI.Error.apiError(
                statusCode: statusCode,
                message: "extract-products failed (\(statusCode))"
            )
        }

        do {
            return try JSONDecoder().decode(ExtractProductsPayload.self, from: data)
        } catch {
            throw ExtractProductsAPI.Error.decodingFailure
        }
    }
}

private nonisolated struct APIErrorBody: Decodable, Sendable {
    let error: String
}
