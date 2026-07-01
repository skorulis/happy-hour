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
            if let preferredSuburbId {
                mutableVenue.suburbId = preferredSuburbId
            } else {
                try Self.linkSuburb(for: &mutableVenue, in: db)
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
                    lastCrawlDate: existing.lastCrawlDate,
                    lastCrawlUrl: existing.lastCrawlUrl,
                    lastExtractionDate: existing.lastExtractionDate,
                    status: importedStatus == .broken ? .broken : existing.status,
                    json: mutableVenue.json
                )
                try mutableVenue.update(db)
                return false
            } else {
                mutableVenue.id = nil
                try mutableVenue.insert(db)
                return true
            }
        }
    }

    @discardableResult
    func upsert(places: [GooglePlace], suburbId: Int64? = nil) throws -> Int {
        var newCount = 0
        for place in places {
            guard place.isImportable else {
                if place.businessStatus == .closedPermanently,
                   let existing = try find(googleMapId: place.id),
                   let existingId = existing.id
                {
                    try delete(id: existingId)
                }
                continue
            }
            if try upsert(try Venue(from: place), preferredSuburbId: suburbId) {
                newCount += 1
            }
        }
        return newCount
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

    @discardableResult
    func delete(id: Int64) throws -> Bool {
        try store.dbQueue.write { db in
            try Venue.deleteOne(db, key: id)
        }
    }

    func updateLastCrawlDate(venueId: Int64, date: Date, url: String?) throws {
        try store.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE venue SET last_crawl_date = ?, last_crawl_url = ? WHERE id = ?",
                arguments: [date, url, venueId]
            )
        }
    }

    func updateLastExtractionDate(venueId: Int64, date: Date) throws {
        try store.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE venue SET last_extraction_date = ? WHERE id = ?",
                arguments: [date, venueId]
            )
        }
    }

    func updateStatus(venueId: Int64, status: VenueStatus) throws {
        try store.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE venue SET status = ? WHERE id = ?",
                arguments: [status.rawValue, venueId]
            )
        }
    }

    func updateHeroImage(venueId: Int64, url: String?) throws {
        try store.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE venue SET hero_image = ? WHERE id = ?",
                arguments: [url, venueId]
            )
        }
    }

    private static func linkSuburb(for venue: inout Venue, in db: Database) throws {
        guard let jsonData = venue.json.data(using: .utf8),
              let place = try? JSONDecoder().decode(GooglePlace.self, from: jsonData),
              let address = place.formattedAddress,
              let extracted = SuburbExtractor.extract(from: address)
        else {
            return
        }

        venue.suburbId = try SuburbRepository.resolve(
            name: extracted.name,
            postcode: extracted.postcode,
            state: extracted.state,
            in: db
        )
    }
}
