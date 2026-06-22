//Created by Alex Skorulis on 22/6/2026.

import Foundation
@preconcurrency import GRDB

nonisolated struct Suburb: Codable, Sendable {
    var id: Int64?
    let name: String
    let postcode: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case postcode
    }

    init(id: Int64? = nil, name: String, postcode: String? = nil) {
        self.id = id
        self.name = name
        self.postcode = postcode
    }
}

nonisolated extension Suburb: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "suburb"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
