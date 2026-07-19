//Created by Alex Skorulis on 15/6/2026.

import ASKCore
import Foundation

enum GooglePlacesAPI {

    enum Error: Swift.Error, Sendable {
        case invalidResponse
        case apiError(statusCode: Int, message: String)
        case decodingFailure
    }

    nonisolated static let placeFieldMask =
        "places.id,places.displayName,places.location,places.formattedAddress,places.websiteUri,places.types,places.regularOpeningHours,places.businessStatus,places.rating"
    nonisolated static let textSearchFieldMask = "\(placeFieldMask),nextPageToken"
    nonisolated static let nearbySearchFieldMask = placeFieldMask

    nonisolated static func searchTextRequest(
        apiKey: String,
        textQuery: String,
        includedType: String? = nil,
        regionCode: String? = nil,
        pageToken: String? = nil
    ) -> HTTPJSONRequest<GooglePlacesSearchResponse> {
        var request = HTTPJSONRequest<GooglePlacesSearchResponse>(
            endpoint: "https://places.googleapis.com/v1/places:searchText",
            body: TextSearchBody(
                textQuery: textQuery,
                includedType: includedType,
                regionCode: regionCode,
                pageToken: pageToken
            )
        )
        request.headers["X-Goog-Api-Key"] = apiKey
        request.headers["X-Goog-FieldMask"] = textSearchFieldMask
        return request
    }

    nonisolated static func searchNearbyRequest(
        apiKey: String,
        latitude: Double,
        longitude: Double,
        radiusMeters: Double,
        includedTypes: [String],
        maxResultCount: Int = 20
    ) -> HTTPJSONRequest<GooglePlacesSearchResponse> {
        var request = HTTPJSONRequest<GooglePlacesSearchResponse>(
            endpoint: "https://places.googleapis.com/v1/places:searchNearby",
            body: NearbySearchBody(
                includedTypes: includedTypes,
                maxResultCount: maxResultCount,
                locationRestriction: .init(
                    circle: .init(
                        center: .init(latitude: latitude, longitude: longitude),
                        radius: radiusMeters
                    )
                )
            )
        )
        request.headers["X-Goog-Api-Key"] = apiKey
        request.headers["X-Goog-FieldMask"] = nearbySearchFieldMask
        return request
    }
}

private struct TextSearchBody: Encodable, Sendable {
    let textQuery: String
    let pageSize: Int = 20
    let includedType: String?
    let regionCode: String?
    let pageToken: String?
}

private struct NearbySearchBody: Encodable, Sendable {
    let includedTypes: [String]
    let maxResultCount: Int
    let locationRestriction: LocationRestriction

    struct LocationRestriction: Encodable, Sendable {
        let circle: Circle
    }

    struct Circle: Encodable, Sendable {
        let center: Center
        let radius: Double
    }

    struct Center: Encodable, Sendable {
        let latitude: Double
        let longitude: Double
    }
}
