//Created by Alex Skorulis on 27/7/2026.

import Foundation
@preconcurrency import GRDB

nonisolated struct DealSourceLink: Codable, Sendable {
    var id: Int64?
    let dealId: Int64
    let dealSourceId: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case dealId = "deal_id"
        case dealSourceId = "deal_source_id"
    }

    init(
        id: Int64? = nil,
        dealId: Int64,
        dealSourceId: Int64
    ) {
        self.id = id
        self.dealId = dealId
        self.dealSourceId = dealSourceId
    }
}

nonisolated extension DealSourceLink: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "deal_source_link"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
