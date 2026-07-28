//Created by Alex Skorulis on 15/6/2026.

import Foundation
@preconcurrency import GRDB

final class VenueRepository {

    private let store: SQLStore

    init(store: SQLStore) {
        self.store = store
    }

    @discardableResult
    func upsert(
        _ venue: Venue,
        preferredSuburbId: Int64? = nil,
        countryIso3: String? = nil
    ) throws -> Bool {
        try store.dbQueue.write { db in
            var mutableVenue = venue
            try Self.linkSuburb(
                for: &mutableVenue,
                preferredSuburbId: preferredSuburbId,
                countryIso3: countryIso3,
                in: db
            )
            if mutableVenue.suburbId == nil, let preferredSuburbId {
                mutableVenue.suburbId = preferredSuburbId
            }

            if let existing = try Venue
                .filter(Column("google_map_id") == mutableVenue.googleMapId)
                .fetchOne(db)
            {
                let importedStatus = Venue.statusWhenImported(from: mutableVenue.websiteUri)
                mutableVenue = Venue(
                    id: existing.id,
                    suburbId: mutableVenue.suburbId,
                    googleMapId: mutableVenue.googleMapId,
                    name: mutableVenue.name,
                    lat: mutableVenue.lat,
                    lng: mutableVenue.lng,
                    websiteUri: mutableVenue.websiteUri,
                    heroImage: existing.heroImage,
                    heroR2Url: existing.heroR2Url,
                    blurb: existing.blurb,
                    contactEmail: existing.contactEmail,
                    googleRating: mutableVenue.googleRating,
                    googleUserRatingCount: mutableVenue.googleUserRatingCount,
                    lastCrawlDate: existing.lastCrawlDate,
                    lastCrawlUrl: existing.lastCrawlUrl,
                    lastExtractionDate: existing.lastExtractionDate,
                    lastUpdate: .now,
                    status: importedStatus == .broken ? .broken : existing.status,
                    json: mutableVenue.json
                )
                try mutableVenue.update(db)
                return false
            } else {
                mutableVenue = Venue(
                    id: nil,
                    suburbId: mutableVenue.suburbId,
                    googleMapId: mutableVenue.googleMapId,
                    name: mutableVenue.name,
                    lat: mutableVenue.lat,
                    lng: mutableVenue.lng,
                    websiteUri: mutableVenue.websiteUri,
                    heroImage: mutableVenue.heroImage,
                    heroR2Url: mutableVenue.heroR2Url,
                    blurb: mutableVenue.blurb,
                    contactEmail: mutableVenue.contactEmail,
                    googleRating: mutableVenue.googleRating,
                    googleUserRatingCount: mutableVenue.googleUserRatingCount,
                    lastCrawlDate: mutableVenue.lastCrawlDate,
                    lastCrawlUrl: mutableVenue.lastCrawlUrl,
                    lastExtractionDate: mutableVenue.lastExtractionDate,
                    lastUpdate: .now,
                    status: mutableVenue.status,
                    json: mutableVenue.json
                )
                try mutableVenue.insert(db)
                return true
            }
        }
    }

    @discardableResult
    func upsert(
        places: [GooglePlace],
        suburbId: Int64? = nil,
        countryIso3: String? = nil
    ) throws -> VenueUpsertResults {
        let parser = try addressParser(forSuburbId: suburbId, countryIso3: countryIso3)
        var newCount = 0
        var droppedCount = 0
        for place in places {
            guard place.isImportable else {
                droppedCount += 1
                if place.businessStatus == .closedPermanently,
                   let existing = try find(googleMapId: place.id),
                   let existingId = existing.id
                {
                    try delete(id: existingId)
                }
                continue
            }
            guard let address = place.formattedAddress,
                  parser.parse(from: address) != nil
            else {
                droppedCount += 1
                continue
            }
            if try upsert(
                try Venue(from: place),
                preferredSuburbId: suburbId,
                countryIso3: countryIso3
            ) {
                newCount += 1
            }
        }
        return VenueUpsertResults(newVenues: newCount, droppedVenues: droppedCount)
    }

    func all() throws -> [Venue] {
        try store.dbQueue.read { db in
            try Venue.fetchAll(db)
        }
    }

    func find(googleMapId: String) throws -> Venue? {
        try store.dbQueue.read { db in
            try Venue
                .filter(Column("google_map_id") == googleMapId)
                .fetchOne(db)
        }
    }

    func find(id: Int64) throws -> Venue? {
        try store.dbQueue.read { db in
            try Venue.fetchOne(db, key: id)
        }
    }

    func find(suburbId: Int64) throws -> [Venue] {
        try store.dbQueue.read { db in
            try Venue
                .filter(Column("suburb_id") == suburbId)
                .order(Column("name"))
                .fetchAll(db)
        }
    }

    /// Minimum great-circle distance (km) to a non-broken venue with an approved deal
    /// outside `excludingSuburbId`, capped at `maxKm`. Returns nil when none are within that cap.
    func minimumApprovedDealDistanceKm(
        fromLat lat: Double,
        lng: Double,
        excludingSuburbId: Int64,
        maxKm: Double
    ) throws -> Double? {
        try store.dbQueue.read { db in
            let distanceSQL = """
                6371.0 * acos(
                  MIN(1.0, MAX(-1.0,
                    cos(? * 0.017453292519943295) * cos(v.lat * 0.017453292519943295) *
                    cos((v.lng - ?) * 0.017453292519943295) +
                    sin(? * 0.017453292519943295) * sin(v.lat * 0.017453292519943295)
                  ))
                )
                """
            let latDelta = maxKm / 111.0
            let cosLat = max(cos(lat * .pi / 180.0), 0.01)
            let lngDelta = maxKm / (111.0 * cosLat)

            return try Double.fetchOne(
                db,
                sql: """
                    SELECT MIN(\(distanceSQL)) AS min_distance
                    FROM venue v
                    INNER JOIN deal d ON d.venue_id = v.id AND d.status = ?
                    WHERE v.status != ?
                      AND (v.suburb_id IS NULL OR v.suburb_id != ?)
                      AND v.lat BETWEEN ? AND ?
                      AND v.lng BETWEEN ? AND ?
                      AND (\(distanceSQL)) <= ?
                    """,
                arguments: [
                    lat, lng, lat,
                    DealStatus.approved.rawValue,
                    VenueStatus.broken.rawValue,
                    excludingSuburbId,
                    lat - latDelta,
                    lat + latDelta,
                    lng - lngDelta,
                    lng + lngDelta,
                    lat, lng, lat,
                    maxKm,
                ]
            )
        }
    }

    func countsBySuburbId() throws -> [Int64: Int] {
        try store.dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT suburb_id, COUNT(*) AS count
                FROM venue
                WHERE suburb_id IS NOT NULL
                GROUP BY suburb_id
                """)
            return Dictionary(uniqueKeysWithValues: rows.compactMap { row in
                guard let suburbId: Int64 = row["suburb_id"] else { return nil }
                return (suburbId, Int(row["count"] ?? 0))
            })
        }
    }

    @discardableResult
    func delete(id: Int64) throws -> Bool {
        try store.dbQueue.write { db in
            try Venue.deleteOne(db, key: id)
        }
    }

    func updateLastCrawlDate(venueId: Int64, date: Date, url: String?) throws {
        try store.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE venue SET last_crawl_date = ?, last_crawl_url = ?, last_update = ? WHERE id = ?",
                arguments: [date, url, Date(), venueId]
            )
        }
    }

    func updateLastExtractionDate(venueId: Int64, date: Date) throws {
        try store.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE venue SET last_extraction_date = ?, last_update = ? WHERE id = ?",
                arguments: [date, Date(), venueId]
            )
        }
    }

    func updateStatus(venueId: Int64, status: VenueStatus) throws {
        try store.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE venue SET status = ?, last_update = ? WHERE id = ?",
                arguments: [status.rawValue, Date(), venueId]
            )
        }
    }

    func updateHeroImage(venueId: Int64, url: String?) throws {
        try store.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE venue SET hero_image = ?, last_update = ? WHERE id = ?",
                arguments: [url, Date(), venueId]
            )
        }
    }

    func updateHeroR2Url(venueId: Int64, url: String?) throws {
        try store.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE venue SET hero_r2_url = ?, last_update = ? WHERE id = ?",
                arguments: [url, Date(), venueId]
            )
        }
    }

    func clearHeroImageFields(venueId: Int64) throws {
        try store.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE venue SET hero_image = NULL, hero_r2_url = NULL, last_update = ? WHERE id = ?",
                arguments: [Date(), venueId]
            )
        }
    }

    func updateBlurb(venueId: Int64, blurb: String) throws {
        try store.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE venue SET blurb = ?, last_update = ? WHERE id = ?",
                arguments: [blurb, Date(), venueId]
            )
        }
    }

    func updateContactEmail(venueId: Int64, contactEmail: String?) throws {
        try store.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE venue SET contact_email = ?, last_update = ? WHERE id = ?",
                arguments: [contactEmail, Date(), venueId]
            )
        }
    }

    /// Sets `contact_email` only when the venue currently has no non-empty value.
    @discardableResult
    func setContactEmailIfEmpty(venueId: Int64, contactEmail: String) throws -> Bool {
        let trimmed = contactEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        return try store.dbQueue.write { db in
            guard let existing = try Venue.fetchOne(db, key: venueId) else { return false }
            let current = existing.contactEmail?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard current.isEmpty else { return false }

            try db.execute(
                sql: "UPDATE venue SET contact_email = ?, last_update = ? WHERE id = ?",
                arguments: [trimmed, Date(), venueId]
            )
            return true
        }
    }

    private func addressParser(
        forSuburbId suburbId: Int64?,
        countryIso3: String? = nil
    ) throws -> any AddressParser {
        guard let suburbId else {
            return AddressParserRegistry.parser(forCountryIso3OrDefault: countryIso3)
        }
        return try store.dbQueue.read { db in
            try Self.addressParser(forSuburbId: suburbId, countryIso3: countryIso3, in: db)
        }
    }

    private static func addressParser(
        forSuburbId suburbId: Int64?,
        countryIso3: String? = nil,
        in db: Database
    ) throws -> any AddressParser {
        AddressParserRegistry.parser(
            forCountryIso3OrDefault: try resolvedCountryIso3(
                forSuburbId: suburbId,
                fallback: countryIso3,
                in: db
            )
        )
    }

    private static func countryIso3(forSuburbId suburbId: Int64?, in db: Database) throws -> String? {
        guard let suburbId,
              let suburb = try Suburb.fetchOne(db, key: suburbId),
              let countryId = suburb.countryId,
              let country = try Country.fetchOne(db, key: countryId)
        else {
            return nil
        }
        return country.iso3
    }

    private static func resolvedCountryIso3(
        forSuburbId suburbId: Int64?,
        fallback: String?,
        in db: Database
    ) throws -> String? {
        try countryIso3(forSuburbId: suburbId, in: db) ?? fallback
    }

    private static func linkSuburb(
        for venue: inout Venue,
        preferredSuburbId: Int64?,
        countryIso3: String? = nil,
        in db: Database
    ) throws {
        guard let jsonData = venue.json.data(using: .utf8),
              let place = try? JSONDecoder().decode(GooglePlace.self, from: jsonData),
              let address = place.formattedAddress
        else {
            return
        }

        let suburbIdForCountry = venue.suburbId ?? preferredSuburbId
        let resolvedCountry = try resolvedCountryIso3(
            forSuburbId: suburbIdForCountry,
            fallback: countryIso3,
            in: db
        )
        let parser = AddressParserRegistry.parser(forCountryIso3OrDefault: resolvedCountry)
        guard let parsed = parser.parse(from: address) else {
            return
        }

        venue.suburbId = try SuburbRepository.resolve(
            name: parsed.suburb,
            postcode: parsed.postcode,
            state: parsed.state,
            countryIso3: resolvedCountry,
            in: db
        )
    }
}
