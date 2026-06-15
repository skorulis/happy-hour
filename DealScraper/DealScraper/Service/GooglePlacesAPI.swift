//Created by Alex Skorulis on 15/6/2026.

import Foundation

enum GooglePlacesAPI {

    enum Error: Swift.Error, Sendable {
        case invalidResponse
        case apiError(statusCode: Int, message: String)
        case decodingFailure
    }

    nonisolated static let defaultFieldMask = "places.id,places.displayName,places.location,places.formattedAddress,places.types"

    nonisolated static func searchText(
        apiKey: String,
        textQuery: String,
        includedType: String? = nil,
        regionCode: String? = nil,
        pageToken: String? = nil,
        fetch: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse)
    ) async throws -> GooglePlacesSearchResponse {
        var requestBody: [String: Any] = [
            "textQuery": textQuery,
            "pageSize": 20,
        ]

        if let includedType {
            requestBody["includedType"] = includedType
        }
        if let regionCode {
            requestBody["regionCode"] = regionCode
        }
        if let pageToken {
            requestBody["pageToken"] = pageToken
        }

        let endpoint = URL(string: "https://places.googleapis.com/v1/places:searchText")!
        return try await performSearch(
            endpoint: endpoint,
            apiKey: apiKey,
            requestBody: requestBody,
            fetch: fetch
        )
    }

    nonisolated static func searchNearby(
        apiKey: String,
        latitude: Double,
        longitude: Double,
        radiusMeters: Double,
        includedTypes: [String],
        maxResultCount: Int = 20,
        fetch: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse)
    ) async throws -> GooglePlacesSearchResponse {
        let requestBody: [String: Any] = [
            "includedTypes": includedTypes,
            "maxResultCount": maxResultCount,
            "locationRestriction": [
                "circle": [
                    "center": [
                        "latitude": latitude,
                        "longitude": longitude,
                    ],
                    "radius": radiusMeters,
                ],
            ],
        ]

        let endpoint = URL(string: "https://places.googleapis.com/v1/places:searchNearby")!
        return try await performSearch(
            endpoint: endpoint,
            apiKey: apiKey,
            requestBody: requestBody,
            fetch: fetch
        )
    }

    nonisolated private static func performSearch(
        endpoint: URL,
        apiKey: String,
        requestBody: [String: Any],
        fetch: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse)
    ) async throws -> GooglePlacesSearchResponse {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue(defaultFieldMask, forHTTPHeaderField: "X-Goog-FieldMask")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await fetch(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw Error.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            let message = errorMessage(from: data) ?? String(data: data, encoding: .utf8) ?? "Unknown error"
            throw Error.apiError(statusCode: httpResponse.statusCode, message: message)
        }

        guard let searchResponse = try? JSONDecoder().decode(GooglePlacesSearchResponse.self, from: data) else {
            throw Error.decodingFailure
        }

        return searchResponse
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
