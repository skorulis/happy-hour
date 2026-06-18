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
    let title: String?
    let imageURL: String?
    let sourceURL: String?
    let details: String?
    let conditions: String?
    var status: DealStatus

    enum CodingKeys: String, CodingKey {
        case id
        case venueId = "venue_id"
        case title
        case imageURL = "image_url"
        case sourceURL = "source_url"
        case details
        case conditions
        case status
    }

    init(
        id: Int64? = nil,
        venueId: Int64,
        title: String? = nil,
        imageURL: String? = nil,
        sourceURL: String? = nil,
        details: String? = nil,
        conditions: String? = nil,
        status: DealStatus = .new
    ) {
        self.id = id
        self.venueId = venueId
        self.title = title
        self.imageURL = imageURL
        self.sourceURL = sourceURL
        self.details = details
        self.conditions = conditions
        self.status = status
    }
}

nonisolated extension Deal: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "deal"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
