//Created by Alex Skorulis on 17/7/2026.

import Foundation
@preconcurrency import GRDB

nonisolated struct Country: Codable, Sendable {
    var id: Int64?
    let name: String
    let iso3: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case iso3
    }

    init(
        id: Int64? = nil,
        name: String,
        iso3: String
    ) {
        self.id = id
        self.name = name
        self.iso3 = iso3
    }
}

nonisolated extension Country: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "country"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

extension Country {
    static let australia = Country(name: "Australia", iso3: "AUS")
    static let newZealand = Country(name: "New Zealand", iso3: "NZL")

    static let defaults: [Country] = [.australia, .newZealand]
}
