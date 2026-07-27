//Created by Alex Skorulis on 15/6/2026.

import Foundation
@preconcurrency import GRDB

final class VenueRepository {

    private let store: SQLStore

    init(store: SQLStore) {
        self.store = store
    }

    @discardableResult
    func upsert(_ venue: Venue, preferredSuburbId: Int64? = nil) throws -> Bool {
        try store.dbQueue.write { db in
            var mutableVenue = venue
            try Self.linkSuburb(
                for: &mutableVenue,
                preferredSuburbId: preferredSuburbId,
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
    func upsert(places: [GooglePlace], suburbId: Int64? = nil) throws -> VenueUpsertResults {
        let parser = try addressParser(forSuburbId: suburbId)
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
            if try upsert(try Venue(from: place), preferredSuburbId: suburbId) {
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

    private func addressParser(forSuburbId suburbId: Int64?) throws -> any AddressParser {
        guard let suburbId else {
            return AddressParserRegistry.parser(forCountryIso3OrDefault: nil)
        }
        return try store.dbQueue.read { db in
            try Self.addressParser(forSuburbId: suburbId, in: db)
        }
    }

    private static func addressParser(forSuburbId suburbId: Int64?, in db: Database) throws -> any AddressParser {
        guard let suburbId,
              let suburb = try Suburb.fetchOne(db, key: suburbId),
              let countryId = suburb.countryId,
              let country = try Country.fetchOne(db, key: countryId)
        else {
            return AddressParserRegistry.parser(forCountryIso3OrDefault: nil)
        }
        return AddressParserRegistry.parser(forCountryIso3OrDefault: country.iso3)
    }

    private static func linkSuburb(
        for venue: inout Venue,
        preferredSuburbId: Int64?,
        in db: Database
    ) throws {
        guard let jsonData = venue.json.data(using: .utf8),
              let place = try? JSONDecoder().decode(GooglePlace.self, from: jsonData),
              let address = place.formattedAddress
        else {
            return
        }

        let parser = try addressParser(
            forSuburbId: venue.suburbId ?? preferredSuburbId,
            in: db
        )
        guard let parsed = parser.parse(from: address) else {
            return
        }

        venue.suburbId = try SuburbRepository.resolve(
            name: parsed.suburb,
            postcode: parsed.postcode,
            state: parsed.state,
            in: db
        )
    }
}
