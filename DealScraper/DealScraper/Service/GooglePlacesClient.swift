//Created by Alex Skorulis on 15/6/2026.

import Foundation

final class GooglePlacesClient: Sendable {

    typealias Error = GooglePlacesAPI.Error

    private let fetch: @Sendable (URLRequest) async throws -> (Data, URLResponse)

    nonisolated init(session: URLSession = .shared) {
        self.fetch = { try await session.data(for: $0) }
    }

    nonisolated init(fetch: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse)) {
        self.fetch = fetch
    }

    nonisolated func searchText(
        apiKey: String,
        textQuery: String,
        includedType: String? = nil,
        regionCode: String? = nil,
        pageToken: String? = nil
    ) async throws -> GooglePlacesSearchResponse {
        try await GooglePlacesAPI.searchText(
            apiKey: apiKey,
            textQuery: textQuery,
            includedType: includedType,
            regionCode: regionCode,
            pageToken: pageToken,
            fetch: fetch
        )
    }

    nonisolated func searchNearby(
        apiKey: String,
        latitude: Double,
        longitude: Double,
        radiusMeters: Double,
        includedTypes: [String],
        maxResultCount: Int = 20
    ) async throws -> GooglePlacesSearchResponse {
        try await GooglePlacesAPI.searchNearby(
            apiKey: apiKey,
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters,
            includedTypes: includedTypes,
            maxResultCount: maxResultCount,
            fetch: fetch
        )
    }
}
