//Created by Alex Skorulis on 17/6/2026.

import Foundation
@preconcurrency import GRDB

nonisolated enum DealStatus: String, Codable, Sendable {
    case new
    case approved
    case rejected
}

nonisolated struct Deal: Codable, Sendable {
    var id: Int64?
    let venueId: Int64
    var title: String?
    var creativeURL: String?
    var sourceURL: String?
    var details: String?
    var conditions: String?
    var status: DealStatus
    var updateDate: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case venueId = "venue_id"
        case title
        case creativeURL = "creative_url"
        case sourceURL = "source_url"
        case details
        case conditions
        case status
        case updateDate = "update_date"
    }

    init(
        id: Int64? = nil,
        venueId: Int64,
        title: String? = nil,
        creativeURL: String? = nil,
        sourceURL: String? = nil,
        details: String? = nil,
        conditions: String? = nil,
        status: DealStatus = .new,
        updateDate: Date? = nil
    ) {
        self.id = id
        self.venueId = venueId
        self.title = title
        self.creativeURL = creativeURL
        self.sourceURL = sourceURL
        self.details = details
        self.conditions = conditions
        self.status = status
        self.updateDate = updateDate
    }
}

nonisolated extension Deal: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "deal"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
