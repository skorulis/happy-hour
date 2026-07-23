//Created by Alex Skorulis on 15/6/2026.

import Foundation

nonisolated struct GooglePlacesSearchResponse: Decodable, Sendable {
    let places: [GooglePlace]
    let nextPageToken: String?
}

nonisolated struct GooglePlaceSummaries: Decodable, Sendable {
    let id: String?
    let editorialSummary: GooglePlace.LocalizedText?
    let reviewSummary: ReviewSummary?
    let generativeSummary: GenerativeSummary?

    struct ReviewSummary: Decodable, Sendable {
        let text: GooglePlace.LocalizedText?
        let flagContentUri: String?
        let disclosureText: GooglePlace.LocalizedText?
        let reviewsUri: String?
    }

    struct GenerativeSummary: Decodable, Sendable {
        let overview: GooglePlace.LocalizedText?
        let overviewFlagContentUri: String?
        let disclosureText: GooglePlace.LocalizedText?
    }
}

nonisolated enum GooglePlaceBusinessStatus: String, Codable, Sendable {
    case operational = "OPERATIONAL"
    case closedTemporarily = "CLOSED_TEMPORARILY"
    case closedPermanently = "CLOSED_PERMANENTLY"

    var isClosed: Bool {
        switch self {
        case .operational:
            return false
        case .closedTemporarily, .closedPermanently:
            return true
        }
    }
}

nonisolated struct GooglePlace: Codable, Sendable {
    let id: String
    let displayName: LocalizedText
    let location: LatLng
    let formattedAddress: String?
    let websiteUri: String?
    let types: [String]?
    let regularOpeningHours: OpeningHours?
    let businessStatus: GooglePlaceBusinessStatus?
    let rating: Double?

    var isImportable: Bool {
        businessStatus?.isClosed != true
    }

    init(
        id: String,
        displayName: LocalizedText,
        location: LatLng,
        formattedAddress: String?,
        websiteUri: String?,
        types: [String]?,
        regularOpeningHours: OpeningHours? = nil,
        businessStatus: GooglePlaceBusinessStatus? = nil,
        rating: Double? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.location = location
        self.formattedAddress = formattedAddress
        self.websiteUri = websiteUri
        self.types = types
        self.regularOpeningHours = regularOpeningHours
        self.businessStatus = businessStatus
        self.rating = rating
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
