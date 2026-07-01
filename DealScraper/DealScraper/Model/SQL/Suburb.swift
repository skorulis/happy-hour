//Created by Alex Skorulis on 22/6/2026.

import Foundation
@preconcurrency import GRDB

nonisolated struct Suburb: Codable, Sendable {
    var id: Int64?
    let name: String
    let postcode: String?
    let state: String?
    let lat: Double?
    let lng: Double?
    let sqkm: Double?
    let statisticArea: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case postcode
        case state
        case lat
        case lng
        case sqkm
        case statisticArea = "statistic_area"
    }

    init(
        id: Int64? = nil,
        name: String,
        postcode: String? = nil,
        state: String? = nil,
        lat: Double? = nil,
        lng: Double? = nil,
        sqkm: Double? = nil,
        statisticArea: String? = nil
    ) {
        self.id = id
        self.name = name
        self.postcode = postcode
        self.state = state
        self.lat = lat
        self.lng = lng
        self.sqkm = sqkm
        self.statisticArea = statisticArea
    }
}

nonisolated extension Suburb: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "suburb"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
