//Created by Alex Skorulis on 22/6/2026.

import Foundation
@preconcurrency import GRDB

nonisolated struct Suburb: Codable, Sendable {
    var id: Int64?
    var countryId: Int64?
    var regionId: Int64?
    let name: String
    let postcode: String?
    let state: String?
    let lat: Double?
    let lng: Double?
    let sqkm: Double?
    let statisticArea: String?
    let blurb: String?
    let heroImage: String?
    let heroR2Url: String?
    let lastCrawlDate: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case countryId = "country_id"
        case regionId = "region_id"
        case name
        case postcode
        case state
        case lat
        case lng
        case sqkm
        case statisticArea = "statistic_area"
        case blurb
        case heroImage = "hero_image"
        case heroR2Url = "hero_r2_url"
        case lastCrawlDate = "last_crawl_date"
    }

    init(
        id: Int64? = nil,
        countryId: Int64? = nil,
        regionId: Int64? = nil,
        name: String,
        postcode: String? = nil,
        state: String? = nil,
        lat: Double? = nil,
        lng: Double? = nil,
        sqkm: Double? = nil,
        statisticArea: String? = nil,
        blurb: String? = nil,
        heroImage: String? = nil,
        heroR2Url: String? = nil,
        lastCrawlDate: Date? = nil
    ) {
        self.id = id
        self.countryId = countryId
        self.regionId = regionId
        self.name = name
        self.postcode = postcode
        self.state = state
        self.lat = lat
        self.lng = lng
        self.sqkm = sqkm
        self.statisticArea = statisticArea
        self.blurb = blurb
        self.heroImage = heroImage
        self.heroR2Url = heroR2Url
        self.lastCrawlDate = lastCrawlDate
    }
}

nonisolated extension Suburb: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "suburb"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
