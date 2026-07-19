//Created by Alex Skorulis on 15/6/2026.

import Foundation
@preconcurrency import GRDB

nonisolated enum VenueStatus: String, Codable, Sendable {
    case normal
    case broken
}

nonisolated struct Venue: Codable, Sendable {
    var id: Int64?
    var suburbId: Int64?
    let googleMapId: String
    let name: String
    let lat: Double
    let lng: Double
    let websiteUri: String?
    let heroImage: String?
    let heroR2Url: String?
    let blurb: String?
    let googleRating: Double?
    let lastCrawlDate: Date?
    let lastCrawlUrl: String?
    let lastExtractionDate: Date?
    let lastUpdate: Date?
    var status: VenueStatus
    let json: String

    enum CodingKeys: String, CodingKey {
        case id
        case suburbId = "suburb_id"
        case googleMapId = "google_map_id"
        case name
        case lat
        case lng
        case websiteUri = "website_uri"
        case heroImage = "hero_image"
        case heroR2Url = "hero_r2_url"
        case blurb
        case googleRating = "google_rating"
        case lastCrawlDate = "last_crawl_date"
        case lastCrawlUrl = "last_crawl_url"
        case lastExtractionDate = "last_extraction_date"
        case lastUpdate = "last_update"
        case status
        case json
    }

    init(
        id: Int64? = nil,
        suburbId: Int64? = nil,
        googleMapId: String,
        name: String,
        lat: Double,
        lng: Double,
        websiteUri: String? = nil,
        heroImage: String? = nil,
        heroR2Url: String? = nil,
        blurb: String? = nil,
        googleRating: Double? = nil,
        lastCrawlDate: Date? = nil,
        lastCrawlUrl: String? = nil,
        lastExtractionDate: Date? = nil,
        lastUpdate: Date? = nil,
        status: VenueStatus = .normal,
        json: String
    ) {
        self.id = id
        self.suburbId = suburbId
        self.googleMapId = googleMapId
        self.name = name
        self.lat = lat
        self.lng = lng
        self.websiteUri = websiteUri
        self.heroImage = heroImage
        self.heroR2Url = heroR2Url
        self.blurb = blurb
        self.googleRating = googleRating
        self.lastCrawlDate = lastCrawlDate
        self.lastCrawlUrl = lastCrawlUrl
        self.lastExtractionDate = lastExtractionDate
        self.lastUpdate = lastUpdate
        self.status = status
        self.json = json
    }

    init(from place: GooglePlace) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let jsonData = try encoder.encode(place)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw EncodingError.invalidValue(
                place,
                EncodingError.Context(codingPath: [], debugDescription: "Failed to encode GooglePlace as UTF-8")
            )
        }

        self.init(
            googleMapId: place.id,
            name: place.displayName.text,
            lat: place.location.latitude,
            lng: place.location.longitude,
            websiteUri: place.websiteUri,
            googleRating: place.rating,
            lastUpdate: .now,
            status: Self.statusWhenImported(from: place.websiteUri),
            json: jsonString
        )
    }

    static func statusWhenImported(from websiteUri: String?) -> VenueStatus {
        guard let websiteUri,
              !websiteUri.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return .broken
        }
        return .normal
    }

    static func touchLastUpdate(_ db: Database, venueId: Int64) throws {
        try db.execute(
            sql: "UPDATE venue SET last_update = ? WHERE id = ?",
            arguments: [Date(), venueId]
        )
    }
}

nonisolated extension Venue: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "venue"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
