//Created by Alex Skorulis on 30/7/2026.

import Foundation
@preconcurrency import GRDB

nonisolated struct VenueFeature: Codable, Sendable {
    var id: Int64?
    let venueId: Int64
    var feature: String

    enum CodingKeys: String, CodingKey {
        case id
        case venueId = "venue_id"
        case feature
    }

    init(
        id: Int64? = nil,
        venueId: Int64,
        feature: String
    ) {
        self.id = id
        self.venueId = venueId
        self.feature = feature
    }
}

nonisolated extension VenueFeature: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "venue_feature"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
