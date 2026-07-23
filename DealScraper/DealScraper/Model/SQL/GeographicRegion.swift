// Created by Alexander Skorulis on 22/7/2026.

import Foundation
@preconcurrency import GRDB

nonisolated struct GeographicRegion: Codable, Sendable {
    var id: Int64?
    let countryId: Int64
    let name: String
    let heroImage: String?
    let heroR2Url: String?

    enum CodingKeys: String, CodingKey {
        case id
        case countryId = "country_id"
        case name
        case heroImage = "hero_image"
        case heroR2Url = "hero_r2_url"
    }

    init(
        id: Int64? = nil,
        countryId: Int64,
        name: String,
        heroImage: String? = nil,
        heroR2Url: String? = nil
    ) {
        self.id = id
        self.countryId = countryId
        self.name = name
        self.heroImage = heroImage
        self.heroR2Url = heroR2Url
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
