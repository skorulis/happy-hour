//Created by Alex Skorulis on 15/6/2026.

import Foundation
@preconcurrency import GRDB

nonisolated struct VenueLinks: Codable, Sendable {
    let venueId: Int64
    var whatsOn: String?
    var instagram: String?
    var facebook: String?

    enum CodingKeys: String, CodingKey {
        case venueId = "venue_id"
        case whatsOn = "whats_on"
        case instagram
        case facebook
    }

    init(
        venueId: Int64,
        whatsOn: String? = nil,
        instagram: String? = nil,
        facebook: String? = nil
    ) {
        self.venueId = venueId
        self.whatsOn = whatsOn
        self.instagram = instagram
        self.facebook = facebook
    }
}

nonisolated extension VenueLinks: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "venue_links"
}
