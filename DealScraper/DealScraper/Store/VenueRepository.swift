//Created by Alex Skorulis on 15/6/2026.

import Foundation
@preconcurrency import GRDB

final class VenueRepository {

    private let store: SQLStore

    init(store: SQLStore) {
        self.store = store
    }

    func upsert(_ venue: Venue) throws {
        try store.dbQueue.write { db in
            if let existingID = try Venue
                .filter(Column("google_map_id") == venue.googleMapId)
                .fetchOne(db)?
                .id
            {
                var updated = venue
                updated.id = existingID
                try updated.update(db)
            } else {
                var newVenue = venue
                newVenue.id = nil
                try newVenue.insert(db)
            }
        }
    }

    func upsert(places: [GooglePlace]) throws {
        for place in places {
            try upsert(try Venue(from: place))
        }
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
