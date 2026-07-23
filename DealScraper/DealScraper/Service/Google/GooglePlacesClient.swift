//Created by Alex Skorulis on 15/6/2026.

import ASKCore
import Foundation

@MainActor
final class GooglePlacesClient: HTTPService {

    typealias Error = GooglePlacesAPI.Error

    private let session: URLSession
    private let requestHandler: ((any HTTPRequest) async throws -> GooglePlacesSearchResponse)?
    private let placeSummariesRequestHandler: ((any HTTPRequest) async throws -> GooglePlaceSummaries)?

    init(session: URLSession = .shared, logger: HTTPLogger? = .init(level: .full)) {
        self.session = session
        self.requestHandler = nil
        self.placeSummariesRequestHandler = nil
        super.init(baseURL: nil, logger: logger)
    }

    init(
        requestHandler: @escaping (any HTTPRequest) async throws -> GooglePlacesSearchResponse
    ) {
        self.session = URLSession.shared
        self.requestHandler = requestHandler
        self.placeSummariesRequestHandler = nil
        super.init(baseURL: nil, logger: nil)
    }

    init(
        placeSummariesRequestHandler: @escaping (any HTTPRequest) async throws -> GooglePlaceSummaries
    ) {
        self.session = URLSession.shared
        self.requestHandler = nil
        self.placeSummariesRequestHandler = placeSummariesRequestHandler
        super.init(baseURL: nil, logger: nil)
    }

    private static let maxTextSearchPages = 3
    private static let pageTokenDelay: Duration = .seconds(2)

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

    func searchTextAllPages(
        apiKey: String,
        textQuery: String,
        includedType: String? = nil,
        regionCode: String? = nil
    ) async throws -> GooglePlacesSearchResponse {
        var allPlaces: [GooglePlace] = []
        var seenIDs = Set<String>()
        var pageToken: String?
        var pageCount = 0

        while pageCount < Self.maxTextSearchPages {
            if pageCount > 0 {
                try await Task.sleep(for: Self.pageTokenDelay)
            }

            let response = try await searchTextPage(
                apiKey: apiKey,
                textQuery: textQuery,
                includedType: includedType,
                regionCode: regionCode,
                pageToken: pageToken
            )

            for place in response.places where seenIDs.insert(place.id).inserted {
                allPlaces.append(place)
            }

            pageCount += 1

            guard let nextToken = response.nextPageToken,
                  !nextToken.isEmpty,
                  pageCount < Self.maxTextSearchPages
            else {
                break
            }

            pageToken = nextToken
        }

        return GooglePlacesSearchResponse(places: allPlaces, nextPageToken: nil)
    }

    private func searchTextPage(
        apiKey: String,
        textQuery: String,
        includedType: String?,
        regionCode: String?,
        pageToken: String?
    ) async throws -> GooglePlacesSearchResponse {
        do {
            return try await searchText(
                apiKey: apiKey,
                textQuery: textQuery,
                includedType: includedType,
                regionCode: regionCode,
                pageToken: pageToken
            )
        } catch let error as GooglePlacesAPI.Error {
            guard pageToken != nil,
                  case let .apiError(_, message) = error,
                  message.contains("INVALID_ARGUMENT")
            else {
                throw error
            }

            try await Task.sleep(for: Self.pageTokenDelay)
            return try await searchText(
                apiKey: apiKey,
                textQuery: textQuery,
                includedType: includedType,
                regionCode: regionCode,
                pageToken: pageToken
            )
        }
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

    func searchArea(
        apiKey: String,
        boundingBox: VenueAreaSweepBoundingBox,
        cellRadiusMeters: Double,
        includedTypes: [String] = VenueAreaSweep.defaultIncludedTypes,
        onProgress: ((VenueAreaSweepProgress) -> Void)? = nil
    ) async throws -> VenueAreaSweepResult {
        try await VenueAreaSweep.sweep(
            boundingBox: boundingBox,
            cellRadiusMeters: cellRadiusMeters,
            searchNearby: { latitude, longitude, radiusMeters in
                let response = try await searchNearby(
                    apiKey: apiKey,
                    latitude: latitude,
                    longitude: longitude,
                    radiusMeters: radiusMeters,
                    includedTypes: includedTypes,
                    maxResultCount: VenueAreaSweep.nearbyResultCap
                )
                return response.places
            },
            onProgress: onProgress
        )
    }

    func getPlaceSummaries(
        apiKey: String,
        placeId: String
    ) async throws -> GooglePlaceSummaries {
        try await performPlaceSummaries(
            GooglePlacesAPI.placeDetailsRequest(apiKey: apiKey, placeId: placeId)
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

    private func performPlaceSummaries<R: HTTPRequest>(
        _ request: R
    ) async throws -> R.ResponseType where R.ResponseType == GooglePlaceSummaries {
        if let placeSummariesRequestHandler {
            return try await placeSummariesRequestHandler(request)
        }

        return try await super.execute(request: request)
    }
}
