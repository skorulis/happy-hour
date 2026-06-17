//Created by Alex Skorulis on 17/6/2026.

import Foundation
@preconcurrency import GRDB

nonisolated struct Deal: Codable, Sendable {
    var id: Int64?
    let venueId: Int64
    let imageURL: String?
    let sourceURL: String?
    let details: String?
    let conditions: String?

    enum CodingKeys: String, CodingKey {
        case id
        case venueId = "venue_id"
        case imageURL = "image_url"
        case sourceURL = "source_url"
        case details
        case conditions
    }

    init(
        id: Int64? = nil,
        venueId: Int64,
        imageURL: String? = nil,
        sourceURL: String? = nil,
        details: String? = nil,
        conditions: String? = nil
    ) {
        self.id = id
        self.venueId = venueId
        self.imageURL = imageURL
        self.sourceURL = sourceURL
        self.details = details
        self.conditions = conditions
    }
}

nonisolated extension Deal: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "deal"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
