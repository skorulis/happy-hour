//Created by Alex Skorulis on 15/6/2026.

import ASKCore
import Foundation

@MainActor
final class GooglePlacesClient: HTTPService {

    typealias Error = GooglePlacesAPI.Error

    private let session: URLSession
    private let requestHandler: ((any HTTPRequest) async throws -> GooglePlacesSearchResponse)?

    init(session: URLSession = .shared, logger: HTTPLogger? = .init(level: .full)) {
        self.session = session
        self.requestHandler = nil
        super.init(baseURL: nil, logger: logger)
    }

    init(
        requestHandler: @escaping (any HTTPRequest) async throws -> GooglePlacesSearchResponse
    ) {
        self.session = URLSession.shared
        self.requestHandler = requestHandler
        super.init(baseURL: nil, logger: nil)
    }

    func searchText(
        apiKey: String,
        textQuery: String,
        includedType: String? = nil,
        regionCode: String? = nil,
        pageToken: String? = nil
    ) async throws -> GooglePlacesSearchResponse {
        try await perform(
            GooglePlacesAPI.searchTextRequest(
                apiKey: apiKey,
                textQuery: textQuery,
                includedType: includedType,
                regionCode: regionCode,
                pageToken: pageToken
            )
        )
    }

    func searchNearby(
        apiKey: String,
        latitude: Double,
        longitude: Double,
        radiusMeters: Double,
        includedTypes: [String],
        maxResultCount: Int = 20
    ) async throws -> GooglePlacesSearchResponse {
        try await perform(
            GooglePlacesAPI.searchNearbyRequest(
                apiKey: apiKey,
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radiusMeters,
                includedTypes: includedTypes,
                maxResultCount: maxResultCount
            )
        )
    }

    private func perform<R: HTTPRequest>(
        _ request: R
    ) async throws -> R.ResponseType where R.ResponseType == GooglePlacesSearchResponse {
        if let requestHandler {
            return try await requestHandler(request)
        }
        
        return try await super.execute(request: request)
    }
}
