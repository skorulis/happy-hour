//Created by Alex Skorulis on 15/6/2026.

import Foundation
@preconcurrency import GRDB

nonisolated struct Venue: Codable, Sendable {
    var id: Int64?
    let googleMapId: String
    let name: String
    let lat: Double
    let lng: Double
    let json: String

    enum CodingKeys: String, CodingKey {
        case id
        case googleMapId = "google_map_id"
        case name
        case lat
        case lng
        case json
    }

    init(
        id: Int64? = nil,
        googleMapId: String,
        name: String,
        lat: Double,
        lng: Double,
        json: String
    ) {
        self.id = id
        self.googleMapId = googleMapId
        self.name = name
        self.lat = lat
        self.lng = lng
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
            json: jsonString
        )
    }
}

nonisolated extension Venue: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "venue"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
