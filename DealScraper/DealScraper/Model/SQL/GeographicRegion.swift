// Created by Alexander Skorulis on 22/7/2026.

import Foundation
@preconcurrency import GRDB

nonisolated struct GeographicRegion: Codable, Sendable {
    var id: Int64?
    let countryId: Int64
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case countryId = "country_id"
        case name
    }

    init(
        id: Int64? = nil,
        countryId: Int64,
        name: String
    ) {
        self.id = id
        self.countryId = countryId
        self.name = name
    }
}

nonisolated extension GeographicRegion: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "geographic_region"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

extension GeographicRegion {
    static let sydneyName = "Sydney"
    static let sunshineCoastName = "Sunshine Coast"
    static let regionalNSWName = "Regional NSW"
    static let australiaRegionNames = [sydneyName, sunshineCoastName, regionalNSWName]
}
