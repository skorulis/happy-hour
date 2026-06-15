//Created by Alex Skorulis on 15/6/2026.

import Foundation

nonisolated struct GooglePlacesSearchResponse: Decodable, Sendable {
    let places: [GooglePlace]
    let nextPageToken: String?
}

nonisolated struct GooglePlace: Codable, Sendable {
    let id: String
    let displayName: LocalizedText
    let location: LatLng
    let formattedAddress: String?
    let types: [String]?

    struct LocalizedText: Codable, Sendable {
        let text: String
        let languageCode: String?
    }

    struct LatLng: Codable, Sendable {
        let latitude: Double
        let longitude: Double
    }
}
