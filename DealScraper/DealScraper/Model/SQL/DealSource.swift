//Created by Alex Skorulis on 15/6/2026.

import Foundation
@preconcurrency import GRDB

nonisolated enum DealSourceType: String, Codable, Sendable {
    case image
    case webpage
    case pdf
}

nonisolated enum DealSourceStatus: String, Codable, Sendable {
    case new
    case approved
}

nonisolated struct DealSource: Codable, Sendable {
    var id: Int64?
    let venueId: Int64
    let url: String
    let type: DealSourceType
    let hash: String
    var status: DealSourceStatus
    var date: Date

    enum CodingKeys: String, CodingKey {
        case id
        case venueId = "venue_id"
        case url
        case type
        case hash
        case status
        case date
    }

    init(
        id: Int64? = nil,
        venueId: Int64,
        url: String,
        type: DealSourceType,
        hash: String,
        status: DealSourceStatus = .new,
        date: Date = .now
    ) {
        self.id = id
        self.venueId = venueId
        self.url = url
        self.type = type
        self.hash = hash
        self.status = status
        self.date = date
    }
}

nonisolated extension DealSource: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "deal_source"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
