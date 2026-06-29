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
    let websiteUri: String?
    let types: [String]?
    let regularOpeningHours: OpeningHours?

    init(
        id: String,
        displayName: LocalizedText,
        location: LatLng,
        formattedAddress: String?,
        websiteUri: String?,
        types: [String]?,
        regularOpeningHours: OpeningHours? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.location = location
        self.formattedAddress = formattedAddress
        self.websiteUri = websiteUri
        self.types = types
        self.regularOpeningHours = regularOpeningHours
    }

    struct LocalizedText: Codable, Sendable {
        let text: String
        let languageCode: String?
    }

    struct LatLng: Codable, Sendable {
        let latitude: Double
        let longitude: Double
    }

    struct OpeningHours: Codable, Sendable {
        let periods: [Period]?
        let weekdayDescriptions: [String]?
        let openNow: Bool?

        struct Period: Codable, Sendable {
            let open: Point?
            let close: Point?

            struct Point: Codable, Sendable {
                let day: Int?
                let hour: Int?
                let minute: Int?
                let truncated: Bool?
            }
        }
    }
}
