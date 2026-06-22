//Created by Alex Skorulis on 15/6/2026.

import Foundation
@preconcurrency import GRDB

final class VenueRepository {

    private let store: SQLStore

    init(store: SQLStore) {
        self.store = store
    }

    @discardableResult
    func upsert(_ venue: Venue) throws -> Bool {
        try store.dbQueue.write { db in
            if let existingID = try Venue
                .filter(Column("google_map_id") == venue.googleMapId)
                .fetchOne(db)?
                .id
            {
                var updated = venue
                updated.id = existingID
                try updated.update(db)
                return false
            } else {
                var newVenue = venue
                newVenue.id = nil
                try newVenue.insert(db)
                return true
            }
        }
    }

    @discardableResult
    func upsert(places: [GooglePlace]) throws -> Int {
        var newCount = 0
        for place in places {
            if try upsert(try Venue(from: place)) {
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

    func updateLastCrawlDate(venueId: Int64, date: Date) throws {
        try store.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE venue SET last_crawl_date = ? WHERE id = ?",
                arguments: [date, venueId]
            )
        }
    }
}
